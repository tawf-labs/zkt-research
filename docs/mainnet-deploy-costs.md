# ZKT Mainnet Deployment Cost Analysis

> **Gas model:** Post-Fusaka (Dec 2025) Ethereum — base fee typically 0.1–0.5 gwei, gas limit 60M.
> **ETH price:** ~$2,000. All gas values from Foundry gas reports (Solidity 0.8.31, `via_ir=true`, `optimizer_runs=1`).

---

## Per-Contract Deploy Gas

| # | Contract | Deploy Gas | Size (bytes) | Source |
|---|---|---|---|---|
| 1 | MockIDRX | 982,318 | 4,898 | Gas report |
| 2 | DonationReceiptNFT | 1,907,370 | 9,310 | Gas report |
| 3 | VotingNFT | 2,287,026 | 11,107 | Gas report |
| 4 | OrganizerNFT | ~1,850,000† | — | Estimated |
| 5 | ParticipationTracker | 1,486,974 | 6,848 | Gas report |
| 6 | Groth16Verifier | 188,300 | 651 | Gas report |
| 7 | ZKVerifier | ~250,000† | — | Estimated |
| 8 | NullifierRegistry | ~200,000† | — | Estimated |
| 9 | ProposalManager | 2,611,867 | 11,892 | Gas report |
| 10 | VotingManager | 1,130,854 | 5,081 | Gas report |
| 11 | ShariaReviewManager | 2,114,319 | 9,626 | Gas report |
| 12 | PoolManager | 2,369,373 | 10,968 | Gas report |
| 13 | ZakatEscrowManager | 3,069,194 | 14,266 | Gas report |
| 14 | PrivateDonationPool | ~1,500,000† | — | Estimated |
| 15 | MilestoneManager | 1,837,188 | 8,183 | Gas report |
| 16 | ZKTCore (orchestrator) | 5,538,881 | 25,942 | Gas report |
| | **Contract deploys subtotal** | **~31,320,000** | | |
| | Role grants + config + overhead | **~8,580,000** | | V9 deploy script |
| | **Full script total** | **39,905,120** | | Sepolia broadcast |

> † Estimated — these contracts are deployed by the script but not exercised by Foundry test suites, so no gas report entry exists. Estimates based on bytecode patterns of similar contracts.

---

## Deployment Scenarios

> **Important:** ZKTCore's constructor requires all 13 dependency addresses. Scenarios that omit contracts require code changes (passing `address(0)` or deploying stub contracts).

### A. Full System (DAO + ZK + Core)

All 16 contracts, all role grants, full configuration.

| Gas Price | Gas Used | ETH Cost | USD (~$2,000/ETH) |
|-----------|----------|----------|---------------------|
| 0.15 gwei (normal) | 39,905,120 | **0.0060 ETH** | **~$12** |
| 1 gwei (busy) | 39,905,120 | **0.0399 ETH** | **~$80** |
| 10 gwei (spike) | 39,905,120 | **0.3991 ETH** | **~$798** |

**What's included:**
- ZK privacy (Noir circuit proofs, nullifier registry, Pedersen commitments)
- DAO governance (proposals, voting, milestones, sharia review)
- Token contracts (IDRX stablecoin mock, receipt NFTs, voting NFTs)
- Private + public donation paths (`donateZKPrivate()` + `donate()`)

---

### B. Without ZK (DAO + Core, no privacy)

Remove ZK verifiers, nullifier registry, and PrivateDonationPool.

| Contracts deployed | 12 |
|---|---|
| Estimated gas | ~28,600,000 |
| Role grants reduced | ~28 calls |

| Gas Price | ETH Cost | USD |
|-----------|----------|-----|
| 0.15 gwei | **0.0043 ETH** | **~$9** |
| 1 gwei | **0.0286 ETH** | **~$57** |
| 10 gwei | **0.2860 ETH** | **~$572** |

**What's removed:** Groth16Verifier, ZKVerifier, NullifierRegistry, PrivateDonationPool.
**What remains:** Public donations only (`donate()`), DAO governance, all token contracts.
**Code change needed:** ZKTCore constructor — pass `address(0)` for ZK addresses; `donateZK()` and `donateZKPrivate()` become unreachable.

---

### C. Without DAO (ZK + Core, no governance)

Remove voting, proposals, milestones, sharia review.

| Contracts deployed | 10 |
|---|---|
| Estimated gas | ~19,500,000 |
| Role grants reduced | ~14 calls |

| Gas Price | ETH Cost | USD |
|-----------|----------|-----|
| 0.15 gwei | **0.0029 ETH** | **~$6** |
| 1 gwei | **0.0195 ETH** | **~$39** |
| 10 gwei | **0.1950 ETH** | **~$390** |

**What's removed:** VotingNFT, OrganizerNFT, VotingManager, ShariaReviewManager, MilestoneManager, ParticipationTracker.
**What remains:** ZK privacy (both donate paths), token contracts, pool management, ProposalManager (dependency for PoolManager/ZakatEscrowManager).
**Code change needed:** ZKTCore constructor — pass `address(0)` for DAO addresses; all governance functions become unreachable.

---

### D. Core Only (no DAO, no ZK)

Minimal donation system — just tokens, pools, and escrow.

| Contracts deployed | 6 |
|---|---|
| Estimated gas | ~17,000,000 |
| Role grants reduced | ~8 calls |

| Gas Price | ETH Cost | USD |
|-----------|----------|-----|
| 0.15 gwei | **0.0026 ETH** | **~$5** |
| 1 gwei | **0.0170 ETH** | **~$34** |
| 10 gwei | **0.1700 ETH** | **~$340** |

**What's deployed:** MockIDRX, DonationReceiptNFT, ProposalManager, PoolManager, ZakatEscrowManager, ZKTCore.
**What's removed:** All ZK contracts, all DAO contracts.
**Code change needed:** ZKTCore constructor — pass `address(0)` for all removed addresses. Only `donate()` works (no privacy, no governance).
**Reality check:** The cost difference between Core Only (~$5) and Full System (~$12) is negligible. Since the full system with core-team-controlled roles works identically (all governance goes through one address), there is **no practical reason** to strip contracts out for cost savings alone.

---

### E. ZK Infrastructure Only

Just the cryptographic layer — verifiers and nullifier registry.

| Contracts deployed | 4 |
|---|---|
| Estimated gas | ~2,040,000 |

| Gas Price | ETH Cost | USD |
|-----------|----------|-----|
| 0.15 gwei | **0.0003 ETH** | **~$0.60** |
| 1 gwei | **0.0020 ETH** | **~$4** |
| 10 gwei | **0.0204 ETH** | **~$41** |

**What's deployed:** Groth16Verifier, ZKVerifier, NullifierRegistry, PrivateDonationPool.
**Note:** Not a functional system on its own. Requires ZKTCore and supporting contracts for end-to-end use.

---

## Core Team Mode (Recommended for Launch)

**The practical answer: deploy everything, but have the core team control all roles.**

ZKTCore's constructor requires all 14 dependency addresses — you cannot omit any contract. However, you don't need a DAO of community members on day one. Instead:

1. **Deploy the full system** (all 16 contracts, ~$12 at normal gas)
2. **Grant all roles to a core team multisig** — the deploy script already does this
3. **Lower governance thresholds** to 1 for initial operation:
   - `setShariaQuorum(1)` — single reviewer instead of 3
   - `setVotingPeriod(1 hours)` — fast iteration instead of 7 days
4. **Operate as a centralized team** — one address creates proposals, votes, reviews, and approves
5. **Transition to community** by granting individual roles to community members over time

This is tested and working — see `sc/test/CoreTeam.t.sol` and `sc/script/CoreTeamDeploy.s.sol`.

### Why Not Strip Contracts?

Even the cheapest "core only" configuration saves at most **$7** versus deploying the full system (at normal gas). The contract-coupling overhead dwarfs any gas savings from omitting contracts. Deploy everything once and control it centrally until the community is ready.

---

## Runtime Gas Costs (per Transaction)

Key function costs that donors/pool operators pay at runtime:

| Function | Gas | At 0.15 gwei | At 1 gwei |
|----------|-----|-------------|-----------|
| `donate()` (public, e2e) | 490,187 | $0.15 | $0.98 |
| `donateZK()` (ZK-public, e2e) | 721,345 | $0.22 | $1.44 |
| `donateZKPrivate()` (ZK-private, e2e) | 170,710 | $0.05 | $0.34 |
| `createCampaignPool()` | 365,601 | $0.11 | $0.73 |
| `castVote()` | 132,909 | $0.04 | $0.27 |
| ETH transfer (baseline) | 21,000 | <$0.01 | $0.04 |
| ERC-20 transfer (baseline) | ~65,000 | $0.02 | $0.13 |

---

## Summary

| Scenario | Gas | 0.15 gwei (normal) | 1 gwei (busy) | 10 gwei (spike) |
|----------|-----|--------------------|---------------|-----------------|
| **A. Full System** | 39.9M | **~$12** | **~$80** | **~$798** |
| **B. Without ZK** | ~28.6M | **~$9** | **~$57** | **~$572** |
| **C. Without DAO** | ~19.5M | **~$6** | **~$39** | **~$390** |
| **D. Core Only** | ~17.0M | **~$5** | **~$34** | **~$340** |
| **E. ZK Only** | ~2.0M | **~$0.60** | **~$4** | **~$41** |

**Bottom line:** Post-Fusaka Ethereum mainnet deployment is extremely affordable. The full 16-contract system with ZK proofs and DAO governance costs **~$12 at normal gas** (0.15 gwei). Even during spikes (10 gwei), it's under $800.

> **Gas model reference:** Base fee ~0.1 gwei (post-Fusaka, 60M gas limit), ETH ~$2,000.
> Verify live: `cast base-fee --rpc-url https://eth.llamarpc.com`
>
> Last updated: 2026-05-22
