# Security Testing Log

**Project**: ZKT — Zero-Knowledge Zakat
**Date**: 2026-06-27
**Scope**: IEEE ICIMTech 2026 — Section IV: Security Analysis
**Summary**: 17 security-focused tests covering circuit boundary values, nullifier race conditions, and mempool front-running. All pass.

---

## 1. Noir Circuit Boundary Value Analysis

**Test file**: `noir-circuits/zkat_eligibility/src/main.nr`
**Framework**: Nargo built-in `#[test]`
**Command**: `nargo test`
**Key**: Overflow guards added to `verify_nisab` and `verify_hawl` functions.

### 1.1 Nisab Eligibility Edge Cases

| Test | Input | Expected | Result | Purpose |
|------|-------|----------|--------|---------|
| `test_nisab_at_exact_threshold` | income=5M, assets=25M, threshold=85M → total=85M | Rejected (not eligible) | **PASS** | `total < threshold` is strict — exactly at threshold is ineligible |
| `test_nisab_just_below_threshold` | income=5M, assets=24,999,999 → total=84,999,999 | Eligible | **PASS** | One unit below threshold passes |
| `test_zero_income_zero_assets` | income=0, assets=0 | Eligible | **PASS** | Zero values do not crash; eligible by default |
| `test_nisab_overflow_rejected` | income at max allowed (u64::MAX/12) | Does not panic | **PASS** | `assert(income <= max_income)` guard passes at boundary |
| `test_nisab_overflow_panics` | income = max+2 (overflows on `* 12`) | `should_fail` — assert panics | **PASS** | Overflow guard correctly rejects oversized input |

### 1.2 Hawl (Lunar Year) Edge Cases

| Test | Input | Expected | Result | Purpose |
|------|-------|----------|--------|---------|
| `test_hawl_exactly_at_deadline` | hawl_start + one_lunar_year == current_time | Hawl met (`>=`) | **PASS** | Inclusive boundary — exactly at deadline qualifies |
| `test_hawl_one_second_before_deadline` | current_time = deadline - 1 | Hawl NOT met | **PASS** | One second before deadline fails |
| `test_hawl_overflow_max_valid` | hawl_start at max safe value, current_time = u64::MAX | Hawl met | **PASS** | Maximum valid timestamp does not overflow |
| `test_hawl_overflow_rejected` | hawl_start = u64::MAX (overflows on `+ one_lunar_year`) | `should_fail` — assert panics | **PASS** | Overflow guard correctly rejects oversized timestamp |

### 1.3 Findings

- **u64 overflow**: Both `income * 12` and `hawl_start + one_lunar_year` are protected by explicit `assert` guards. Without these, Noir release-mode circuits silently wrap on overflow, producing incorrect eligibility results.
- **Threshold semantics**: The circuit uses strict less-than (`<`) for nisab — a recipient whose wealth equals the threshold is **not eligible**. This is intentional Sharia-compliant behavior (mustahik must be *below* nisab).
- **Hawl semantics**: Hawl uses inclusive greater-or-equal (`>=`) — exactly one lunar year qualifies. This is also intentional.

---

## 2. Nullifier Race Conditions (Double-Spend Prevention)

**Test file**: `sc/test/SecurityEdge.t.sol`
**Framework**: Foundry (forge-std)
**Command**: `forge test --match-path test/SecurityEdge.t.sol`

### 2.1 Atomicity of `NullifierRegistry.spend()`

| Test | Gas | Result | Purpose |
|------|-----|--------|---------|
| `test_NullifierDoubleSpend_RevertsSecondSpend` | 40,312 | **PASS** | Direct `.spend()` call on NullifierRegistry: first spend succeeds, second reverts with `"NullifierAlreadySpent"` |
| `test_NullifierRace_DirectRegistrySpend` | 58,857 | **PASS** | Two distinct nullifiers can be spent independently without interference |
| `test_NullifierRace_EndToEndDonateZKRevertsDuplicate` | 1,329,642 | **PASS** | Full `donateZKPrivate()` flow: first donation succeeds, nullifier is marked spent, second donation with same nullifier reverts |

### 2.2 Findings

- The EVM executes `NullifierRegistry.spend()` synchronously within a single transaction. The `mapping(bytes32 => bool)` storage update is atomic with respect to the transaction:
  ```
  // Line 20, NullifierRegistry.sol
  spentNullifiers[nullifier] = true;
  ```
- Any subsequent transaction in the same block that attempts to spend the same nullifier hits the `require(!spentNullifiers[nullifier])` guard and reverts.
- **No concurrency vulnerability exists** at the EVM level — each transaction executes sequentially within the block, and storage writes are durable before the next transaction begins.
- **No reentrancy concern**: `spend()` writes state before any external calls downstream (the `transferFrom` happens after the nullifier is marked).

---

## 3. Mempool Front-Running (Griefing Attack)

**Test file**: `sc/test/SecurityEdge.t.sol`
**Framework**: Foundry (forge-std)

### 3.1 Attack Vector Analysis

| Test | Gas | Result | Purpose |
|------|-----|--------|---------|
| `test_FrontRunning_AttackerCanReplayCalldata` | 1,340,963 | **PASS** | Attacker extracts valid `(proof, publicInputs, nullifier)` from pending tx, submits with own wallet. Attacker pays, donor's tx reverts, pool receives correct funds. |
| `test_FrontRunning_ProofValidityUnaffectedBySender` | 1,295,910 | **PASS** | Demonstrates that the ZK proof is valid regardless of `msg.sender` — any address can submit the same proof. |

### 3.2 Detailed Attack Flow

```
1. Donor generates valid UltraHONK proof + nullifier
2. Donor submits donateZKPrivate(poolId, amount, proof, publicInputs, nullifier)
   → Transaction enters Sepolia mempool (pending)
3. MEV searcher observes pending tx, extracts calldata:
   → (proof, publicInputs, nullifier) are readable in the raw transaction
4. Attacker submits front-run tx with same calldata + higher gas price
5. Block builder includes attacker's tx first:
   → honkVerifier.verify(proof, publicInputs) → true (proof is valid)
   → nullifierRegistry.spend(nullifier) → success (nullifier was fresh)
   → privateDonationPool.donatePrivately(msg.sender, ...) → uses attacker's address!
6. Donor's original tx processes next:
   → honkVerifier.verify(proof, publicInputs) → true (still valid)
   → nullifierRegistry.spend(nullifier) → REVERT "NullifierAlreadySpent"
```

### 3.3 Impact Assessment

| Property | Status |
|----------|--------|
| Funds reach correct pool | **Yes** — `poolRaisedAmount[poolId]` increments correctly |
| Donation amount preserved | **Yes** — amount is in calldata, unchanged |
| Donor identity protected | **No** — attacker pays instead of donor |
| Proof integrity maintained | **Yes** — proof still verifies |
| Nullifier replay prevented | **Yes** — second spend reverts |

**Classification**: **Griefing attack**, not theft. The attacker cannot redirect funds or steal tokens. They can only pay the donation on behalf of the original donor, incurring gas costs for no financial gain. The attack is economically irrational for a profit-motivated MEV searcher.

### 3.4 Root Cause

The circuit's public inputs do NOT include `msg.sender`:

```solidity
// ZKTCore.sol:580-590
function donateZKPrivate(
    uint256 poolId,
    uint256 amount,
    bytes calldata proof,
    bytes32[] calldata publicInputs,
    bytes32 nullifier
) external {
    require(honkVerifier.verify(proof, publicInputs), "Invalid ZK proof");
    nullifierRegistry.spend(nullifier);
    privateDonationPool.donatePrivately(msg.sender, ...);
    //  msg.sender NOT in publicInputs — anyone can relay
}
```

**Mitigation** (future work): Bind the donor address into the circuit as a public input:
```
publicInputs[7] = bytes32(uint256(uint160(msg.sender)));
```
Or require EIP-712 signed authorization from the donor, verified in the same transaction.

---

## 4. Full Suite Coverage Summary

### 4.1 All Test Suites

```
Layer                   Tests   Status
──────────────────────  ──────  ──────
Foundry (Solidity)       46     all pass
  ZKTCoreTest             17    governance, voting, donations, milestones
  ShariaZKProofTest        9    ZK proof submission, quorum, replay
  SecurityEdgeTest         5    nullifier race, front-running griefing
  TestDonateZKPrivate      9    private donation, double-nullifier
  CoreTeamTest             3    centralized governance transition
  TestSepoliaFork          1    Sepolia fork verification
  TestForkDonate           1    fork donation verification
  TestDonateZK             1    donateZK revert reason

Noir Circuit              12    all pass
  eligibility              3    nisab, hawl, eligible/ineligible
  boundary values          9    thresholds, overflow, deadlines

Circom Circuit             5    all pass
  ShariaVoteAggregator     5    valid proof, quorum, binary vote, unanimous, mismatch

Offchain Coordinator       9    all pass
  Coordinator API          9    health, council, voting, double-vote

Frontend (Vitest)         78    all pass
  ABI validation          38    contract addresses + ABI structure
  Type enums              22    ProposalStatus, KYCStatus, CampaignType, etc.
  Contract integrity      18    chain config, checksums, uniqueness
───────────────────────────────
TOTAL                    150    0 failures
```

### 4.2 Execution Log

```
=== Noir Circuit Tests (12/12) ===
[PASS] test_nisab_at_exact_threshold
[PASS] test_nisab_just_below_threshold
[PASS] test_nisab_overflow_rejected
[PASS] test_nisab_overflow_panics
[PASS] test_zero_income_zero_assets
[PASS] test_hawl_exactly_at_deadline
[PASS] test_hawl_one_second_before_deadline
[PASS] test_hawl_overflow_max_valid
[PASS] test_hawl_overflow_rejected
[PASS] test_eligible_recipient
[PASS] test_ineligible_recipient
[PASS] test_hawl_met

=== SecurityEdgeTest (5/5) ===
[PASS] test_NullifierDoubleSpend_RevertsSecondSpend   (40,312 gas)
[PASS] test_NullifierRace_DirectRegistrySpend          (58,857 gas)
[PASS] test_NullifierRace_EndToEndDonateZKRevertsDuplicate (1,329,642 gas)
[PASS] test_FrontRunning_AttackerCanReplayCalldata     (1,340,963 gas)
[PASS] test_FrontRunning_ProofValidityUnaffectedBySender (1,295,910 gas)

=== Full Foundry Suite (46/46) ===
8 test suites, 46 tests passed, 0 failed
```

### 4.3 Replay

All security tests are reproducible via:

```bash
# Noir circuit boundary tests
cd noir-circuits/zkat_eligibility && nargo test

# Foundry security edge tests
cd sc && forge test --match-path test/SecurityEdge.t.sol -vvv

# Full E2E pipeline (all 6 layers)
bash e2e-pipeline.sh
```
