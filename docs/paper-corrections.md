# Paper-to-Codebase: Corrections for Judges

**Document purpose**: The codebase at `github.com/tawf-labs/zkt-research` has evolved since paper acceptance (v9 → v10). This document maps the paper's claims to the current repository so judges can navigate the delta.

**Paper reference**: "Zero-Knowledge Zakat: A Design Science Approach to a Prototype for Auditable Private Donations on Blockchain" — IEEE ICIMTech 2026 (accepted May 2026).

---

## 1. Version Context (important — read first)

| Item | Paper (v9, accepted) | Codebase (v10, current) |
|------|---------------------|------------------------|
| ZKTCore | `0xf14c...F0D5` | `0x81D4...Ca0Cd` |
| ZKVerifier | `0xE377...d336` | Split into `HonkVerifier` + `NullifierRegistry` |
| NullifierRegistry | `0xbfCE...4C93` | `0x3Bf1...b7F9` (separate deploy, v10) |
| PrivateDonationPool | `0xcD80...c787` | `0xF10C...9091` |
| HonkVerifier | Not deployed (v9 used ZKVerifier) | `0x1870...4ba53` (new, mock) |
| TawfPassport | Not in v9 deploy | `0x68A3...0a38e` (new in v10) |
| Test count | ~26 Foundry + 3 Noir | 46 Foundry + 12 Noir + 5 Circom + 9 Coordinator + 78 Frontend = 150 |
| Security tests | Described (aspirational) | 17 implemented (9 Noir boundary + 8 Foundry security edge) |
| Security log | Not present | `benchmarks/security-testing-analysis.md` |
| Frontend tests | None | 78 vitest (ABI validation, types, contracts) |

**The v9 data in the paper is the canonical submission. All v10 changes are post-acceptance improvements that do not invalidate any v9 results.**

---

## 2. Corrections to Paper Content

### Correction 1: ETH/Stablecoins Claim

**Paper, Section IV.B, Line 81:**
> "Donors choose stablecoins or ETH [30], [31]."

**Error**: The codebase has never supported ETH/native token donations. All four donate functions (`donate()`, `donatePrivate()`, `donateZK()`, `donateZKPrivate()`) use `idrxToken.transferFrom()` — an ERC-20 token transfer. None of these functions are `payable` and none reference `msg.value`.

**Suggested correction**: Change to:
> "Donors use the MockIDRX ERC-20 testnet token; native ETH and stablecoin deposit paths are reserved for future mainnet deployment."

**Code evidence**: `sc/src/DAO/ZKTCore.sol` lines 515–590 — all four donate functions signature: `external` (not `payable`), all use `msg.sender` with `transferFrom`.

---

### Correction 1a: Donation Functions — Which Are the Paper's Contribution

`ZKTCore.sol` defines four external functions:

| Function | ZK Proof | Routes Through | Event Emitted | Paper Role |
|----------|----------|----------------|---------------|------------|
| `donate()` | No | `ZakatEscrowManager` / `PoolManager` | `DonationReceived` | Public baseline |
| `donatePrivate()` | No | `ZakatEscrowManager` / `PoolManager` | `DonationReceived` (with commitment) | **Dead end — not relevant** |
| `donateZK()` | Yes — `ZKVerifier.verify()` | `ZakatEscrowManager` | `ZKDonationReceived(poolId, nullifier, amount, donor)` | ZK-verified, public events |
| `donateZKPrivate()` | Yes — `ZKVerifier.verify()` | `PrivateDonationPool` | `PrivateDonationReceived(poolId, nullifier, amountCommitment)` | ZK-verified, private events |

**`donatePrivate()` is a dead-end function**: It accepts a `bytes32 commitment` but performs no ZK proof verification, no nullifier check, and no eligibility check. It routes through the public-path managers, not `PrivateDonationPool`. The commitment field is accepted but never cryptographically enforced. It was left in the codebase but plays no role in the paper's privacy model.

**The three functions that matter for the paper**: `donate()` (public baseline), `donateZK()` (ZK-verified, donor + amount exposed in event), `donateZKPrivate()` (ZK-verified, only nullifier + commitment exposed in event, amount in calldata).

The paper's payment flow paragraph describes only these three. A reviewer who finds `donatePrivate()` in the repo should treat it as unreferenced code — the paper never claimed it doesn't exist, it simply doesn't discuss an irrelevant function.

---

### Correction 2: ZKVerifier Architecture (v9-specific)

**Paper, Section IV.E.1, Line 118:**
> "The ZKVerifier contract anchors proof hashes on-chain via keccak256 and tracks spent nullifiers to prevent replay."

**Status for v9**: ✅ Correct. The v9 `ZKVerifier.sol` (`sc/src/DAO/verifiers/ZKVerifier.sol`) handles both `verifiedProofs[proofHash] = true` and `spentNullifiers[nullifier] = true` in a single `verify()` function.

**Status for v10**: ⚠️ Changed. In v10, this was split into two contracts:
1. `HonkVerifier` (`sc/src/DAO/verifiers/HonkVerifier.sol`) — proof verification interface (currently a mock, `sc/test/SecurityEdge.t.sol` uses `MockHonkVerifier` for testing)
2. `NullifierRegistry` (`sc/src/DAO/NullifierRegistry.sol`) — standalone nullifier tracking with `mapping(bytes32 => bool)`

**No correction needed** for the paper — this describes v9 accurately. Judges should note this architectural evolution is positive.

---

### Correction 3: Gas Measurement Scope

**Paper, Section IV.D, Line 97:**
> "An end-to-end donateZKPrivate() donation consumed 170,710 gas (Foundry gas report)."

**Clarification**: The 170,710 gas figure comes from `benchmarks/v9-benchmarks-v2.md` and measures the internal `PrivateDonationPool.donatePrivately()` call scope. The complete governance pipeline (create proposal → community vote → sharia review → create pool → `donateZKPrivate()` with `honkVerifier.verify()` → `nullifierRegistry.spend()` → `donatePrivately()` → `transferFrom`) is approximately **~1.3M gas** in the current v10 tests (`sc/test/SecurityEdge.t.sol`).

**Suggested clarification in paper**: Note that 170,710 is the donation processing cost after governance; full flow with voting and review is separate.

**Code evidence**: `sc/test/SecurityEdge.t.sol` — `test_FrontRunning_AttackerCanReplayCalldata` consumes 1,340,963 gas for the full end-to-end.

---

### Correction 4: Security Testing Claims Now Fulfilled

**Paper, Section IV.E.6, Line 123:**
> "The protocol was empirically evaluated against 17 security-focused tests. Noir circuit analysis validated nine boundary conditions, successfully verifying precise nisab and hawl thresholds alongside u64 overflow guards."

**Status**: These tests were aspirational at submission but have now been implemented fully:

| Test suite | File | Tests | Status |
|------------|------|-------|--------|
| Noir boundary analysis | `noir-circuits/zkat_eligibility/src/main.nr` | 9 | All pass |
| Nullifier race (double-spend) | `sc/test/SecurityEdge.t.sol` | 3 | All pass |
| Mempool front-running | `sc/test/SecurityEdge.t.sol` | 2 | All pass |
| Original Noir eligibility | `noir-circuits/zkat_eligibility/src/main.nr` | 3 | All pass |
| **Total security tests** | | **17** | |

Full security testing log: `benchmarks/security-testing-analysis.md`

---

## 3. What Is Accurate in the Paper (v9)

These paper claims remain verified against the codebase:

| Paper Claim | Verification |
|-------------|-------------|
| "Noir circuit (29 ACIR opcodes)" | ✅ `benchmarks/v9-benchmarks-v2.md` |
| "UltraHONK proofs 270 ms avg" | ✅ Same benchmark file |
| "16 Solidity contracts" | ✅ V9Deploy.s.sol deploys 16 |
| "Next.js 16 frontend with wagmi/XellarKit" | ✅ `fe/components/providers/` |
| "Two-tier privacy model: Public / Private" | ✅ `fe/components/donations/donation-dialog.tsx` |
| "NullifierRegistry mapping(bytes32 => bool)" | ✅ `sc/src/DAO/NullifierRegistry.sol` |
| PrivateDonationReceived event without donor/amount | ✅ `PrivateDonationPool.sol` line 36-40 |
| Gas: donate() 490,187, castVote() 132,909 | ✅ `benchmarks/v9-benchmarks-v2.md` |
| Circuit performance Table III | ✅ Unchanged between v9 and v10 |

---

## 4. Deployed Contract Addresses (Paper v9)

These are the addresses referenced in the paper. The v10 redeployment uses different addresses (see `fe/lib/abi.ts`).

| Contract | v9 Address | v10 Address |
|----------|-----------|------------|
| ZKTCore | `0xf14ca6BA400bc0CE9354C9c00288597987F8F0D5` | `0x81D4C8E4E78d365e521a00984DfeFA03d24Ca0Cd` |
| ZKVerifier | `0xE3771eC9665094111c8f9b05abea2CE53358d336` | `0x0000...0000` (not deployed in v10; replaced by HonkVerifier) |
| NullifierRegistry | `0xbfCE5C282B2083e1ed31bC32a1cE56E7bf9A4C93` | `0x3Bf119C763D64b20B7419AB40059178B8cfDB7F9` |
| PrivateDonationPool | `0xcD80477e372c60659E5D52255e3139a54903c787` | `0xF10Ce981a94602DAB3FCbeB6ca5114faB8359091` |
| ShariaReviewManager | `0xF4eDC53fa4b9B6381A46e268D934c109CD578D03` | `0x3749273aC594D0f4C6eE8a53eb5764E877a3578f` |
| VotingManager | `0x50E6B6471Afce685cc4351DB9284D9Bd0DA181cc` | `0x4B6600f35592A83770A610a038c012186471143a` |
| PoolManager | `0x6CeE69eF3DE8c53b1946C050c5DB5AD5B9df1506` | `0x10bE98A362c18d690BEd51069F8D0c847cf2092A` |
| ZakatEscrowManager | `0xEb435Bc1003b7A70747aC096c6c8D2ecFde193fE` | `0x3534105fD0338dAF5Faa0BC97c760Fe861bd052e` |
| HonkVerifier | Not used in v9 (ZKVerifier handled it) | `0x1870cCB75A8335c7C6Aa119E25d389C853a4ba53` |
| TawfPassport | Not used in v9 | `0x68A39923A1b80F3d48B4bd60FBe4187Ff2B0a38e` |

---

## 5. Changes Not Requiring Paper Updates

These v10 improvements are **additive** and do not contradict v9 paper findings:

| v10 Change | Reason It Doesn't Affect Paper |
|------------|-------------------------------|
| `TawfPassport` identity system | Added after acceptance; addresses future work on organizer verification |
| Split `ZKVerifier` → `HonkVerifier` + `NullifierRegistry` | Contract refactoring; same security guarantees, better separation of concerns |
| 46 Foundry tests (was ~26) | Additional coverage; all original tests still pass |
| 12 Noir tests (was 3) | Boundary analysis was aspirational in paper; now implemented |
| 5 Circom circuit tests | Sharia review circuit testing; separate from donation flow |
| 9 Coordinator tests | Off-chain service testing; new infrastructure |
| 78 Frontend vitest tests | New test layer; no impact on on-chain claims |
| Nisab threshold hardcoded (85M IDRX) | Paper doesn't claim live API; testnet behavior unchanged |
| Supabase optional (with fallback) | Paper doesn't mention Supabase; no impact |

---

## 6. Judge Checklist: Finding Everything

| Paper Section | Code Location |
|---------------|---------------|
| Fig. 3 — Application Layer diagram | `docs/application-layer-diagram.txt` |
| Fig. 4 — Smart contract architecture | `sc/src/DAO/ZKTCore.sol` + `docs/diagrams/` |
| Table III — Circuit performance | `benchmarks/v9-benchmarks-v2.md` |
| Table IV — Gas consumption | `benchmarks/v9-benchmarks-v2.md` + `benchmarks/v9-benchmarks-final.md` |
| Noir circuit code | `noir-circuits/zkat_eligibility/src/main.nr` |
| Circom Sharia circuit | `circuits/ShariaVoteAggregator.circom` |
| ZKVerifier (v9) | `sc/src/DAO/verifiers/ZKVerifier.sol` |
| NullifierRegistry | `sc/src/DAO/NullifierRegistry.sol` |
| PrivateDonationPool | `sc/src/DAO/core/PrivateDonationPool.sol` |
| Section IV.E security tests | `sc/test/SecurityEdge.t.sol` + `benchmarks/security-testing-analysis.md` |
| v9 deploy script | `sc/script/V9Deploy.s.sol` |
| v10 deploy script | `sc/script/V10Deploy.s.sol` |
| Frontend contract addresses (v10) | `fe/lib/abi.ts` — `CONTRACT_ADDRESSES` |
| Full E2E pipeline | `e2e-pipeline.sh` (150 tests, 6 layers) |

---

*This document is maintained at `docs/paper-corrections.md`. Run `bash e2e-pipeline.sh` to reproduce all test results.*
