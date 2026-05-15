# ZKT: Zero-Knowledge Zakat

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.31-blue.svg)](https://soliditylang.org/)
[![Next.js](https://img.shields.io/badge/Next.js-16.1.1-black.svg)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/)
[![Noir](https://img.shields.io/badge/Noir-1.0.0--beta.21-purple.svg)](https://noir-lang.org/)

Privacy-preserving zakat donations using UltraHONK zero-knowledge proofs on Ethereum Sepolia. Donors contribute zakat with cryptographic anonymity while maintaining verifiable Sharia compliance and institutional accountability.

- **Testnet**: [ziswaf.tawf.foundation](https://ziswaf.tawf.foundation)
- **Paper**: `zk-private-zakat.pdf` (IEEE ICIMTech 2026, 6 pages, 33 references)
- **Authors**: Muhammad Zidan Fatonie, Alexander Agung Santoso Gunawan (BINUS University)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Deployed Contracts (Sepolia)](#deployed-contracts-sepolia)
- [Quick Start](#quick-start)
- [Circuit Performance](#circuit-performance)
- [Project Structure](#project-structure)
- [Smart Contract Architecture](#smart-contract-architecture)
- [ZK Pipeline](#zk-pipeline)
- [Frontend Features](#frontend-features)
- [Testing](#testing)
- [Benchmarks](#benchmarks)
- [Paper](#paper)
- [Acknowledgments](#acknowledgments)
- [License](#license)

---

## Overview

ZKT addresses a critical gap in blockchain-based zakat systems: all existing platforms expose complete donor-recipient transaction records on public ledgers, violating Islamic principles of dignity preservation (nafs protection in maqasid al-shariah).

**Key features:**
- **Noir circuit** (29 ACIR opcodes) encoding nisab + hawl + pedersen nullifier verification
- **UltraHONK proofs** generated via Barretenberg v4.2.1 (246.8ms avg)
- **On-chain verification** through ZKVerifier with nullifier-based double-donation prevention
- **15 Solidity contracts** deployed on Ethereum Sepolia testnet
- **Next.js 15 PWA** frontend with wagmi/XellarKit wallet connectivity
- **Privacy tier toggle** supporting Private, Semi-Private, Verified-Private, and Public modes

## Architecture

```
Donor Frontend (Next.js 15 PWA + wagmi/XellarKit)
    │  wallet connect, tier select, private inputs
    ▼
Off-Chain Proving (Noir + Barretenberg v4.2.1)
    │  nargo compile → nargo execute → bb prove UltraHONK
    │  29 ACIR opcodes, 246.8ms avg prove, 12.0ms avg verify, 8,384 bytes proof
    ▼
Ethereum Sepolia (15 Solidity contracts)
    │  ZKVerifier.verify() → ZKTCore.donateZK()
    │  → NullifierRegistry.spend() → ZakatEscrowManager.donate()
    │  → DonationReceiptNFT.mint() → receipt SBT to donor
    ▼
Donor receives soulbound NFT receipt (proof of zakat payment)
```

## Deployed Contracts (Sepolia)

v8 deployment — all 15 contracts verified onchain.

| Contract | Address |
|----------|---------|
| ZKTCore (v8) | `0xb56a8411C769cb0039e9ae1FdA3ea51424B1b60B` |
| ZKVerifier | `0x1009559B0a3c4a22b4F5503C16B6cD9Bc7f62f3F` |
| NullifierRegistry | `0xeEA85A1870602E8bB0B18BeF8144AD0C8e1E9e49` |
| ProposalManager | `0xc75f1A2B32f034D972afB75E437a1c3A9F467911` |
| VotingManager | `0x56CAF0aFE6CeA849906fdDD06c3358a20e353Fb4` |
| ShariaReviewManager | `0x227cb839365C7F2cB576768432563E6566343af2` |
| PoolManager | `0x8b745Cd7b399E3965088aA367D54F2366A17288c` |
| ZakatEscrowManager | `0x8A085b6Bd8A2f9eCb712c7d861238EdAe982eED1` |
| DonationReceiptNFT | `0x739b75bEeaC0207BeB70a0405f3CF81654D81885` |
| VotingNFT | `0x62AF745f9b7689720129A3A60e2ab0A2892C89B4` |
| OrganizerNFT | `0x8b9bCFc0a1D2f3d7CEfeD6cb279E61e76Af34F8E` |
| ParticipationTracker | `0x521Cc9536Ca85eD9404b1444F5541fB134722dbf` |
| MilestoneManager | `0x5685aeaDAce85819682D28F831321B6e4094Ee75` |
| Groth16Verifier | `0x3A8fF96D7dB26e0A5E7cd47283761bf77531FcdB` |

End-to-end v8 donation verified at [tx 0x6a0b35...b790](https://sepolia.etherscan.io/tx/0x6a0b350821aa5afa309be599b5a64836aefb1c4a25d666a61d94e541967db790), block 10,854,651, consuming 721,345 gas.

## Quick Start

### Prerequisites

- Node.js v22+, pnpm
- Foundry (forge + cast)
- Noir/nargo v1.0.0-beta.21+

### Frontend

```bash
cd fe
pnpm install
pnpm dev       # http://localhost:3000
pnpm build     # production build
```

### Smart Contracts

```bash
cd sc
forge build
forge test      # 26 tests passing
```

### ZK Circuit

```bash
cd noir-circuits/zkat_eligibility
nargo test      # 3 tests passing
nargo compile   # compile to ACIR
nargo execute   # generate witness
```

## Circuit Performance

All benchmarks run on a 16-core Linux machine with Barretenberg v4.2.1.

| Metric | Value |
|--------|-------|
| ACIR opcodes | 29 |
| Brillig opcodes | 44 |
| Expression width | 4 (Bounded) |
| Proof generation (avg) | 246.8 ms |
| Proof generation (min) | 239.0 ms |
| Proof generation (max) | 263.0 ms |
| Proof verification (avg) | 12.0 ms |
| Proof size | 8,384 bytes |
| Verification key size | 1,888 bytes |

On-chain gas consumption (Foundry gas report):

| Function | Gas (avg) |
|----------|-----------|
| `ZKTCore.donate()` | 490,187 |
| `ZKTCore.donateZK()` (e2e) | 721,345 |
| `ZKTCore.castVote()` | 132,909 |
| `ZKTCore.deploy` | 5,314,471 |
| `ZakatEscrowManager.donate()` | 30,884 |

## Project Structure

```
├── fe/                           # Next.js 15 PWA frontend
│   ├── app/                      # App router pages (campaigns, zakat, dashboard, dao)
│   ├── components/
│   │   ├── donations/            # DonationDialog (public + private toggle)
│   │   ├── providers/            # Web3Provider (wagmi + XellarKit)
│   │   ├── shared/               # CampaignCard, ZakatCertificateModal
│   │   └── ui/                   # shadcn/ui components
│   ├── hooks/
│   │   ├── usePrivateDonation.ts # ZK donation pipeline
│   │   └── useWallet.ts          # Wallet state + donate()
│   └── lib/
│       ├── abi.ts                # All 15 contract addresses + ABIs
│   └── aztec-private-donation.ts  # Proof generation pipeline
│
├── sc/                           # Solidity smart contracts
│   ├── src/DAO/
│   │   ├── ZKTCore.sol           # Main orchestrator (v8, donateZK, donate, castVote)
│   │   ├── NullifierRegistry.sol # Nullifier tracking for double-donation prevention
│   │   ├── core/                 # ProposalManager, VotingManager, ShariaReviewManager,
│   │   │                          PoolManager, ZakatEscrowManager, MilestoneManager
│   │   └── verifiers/
│   │       └── HonkVerifier.sol  # IHonkVerifier interface
│   ├── src/tokens/               # MockIDRX, DonationReceiptNFT, VotingNFT, OrganizerNFT
│   ├── src/participants/         # ParticipationTracker
│   ├── script/
│   │   ├── DeployZKT.s.sol       # Full deployment script (15 contracts)
│   │   └── GenerateZKProof.mjs   # Off-chain proof generator
│   └── test/                     # Foundry tests (26 passing)
│
├── noir-circuits/
│   └── zkat_eligibility/         # Noir circuit (nisab + hawl + pedersen nullifier)
│
├── docs/diagrams/                # PlantUML sources + generated PNGs (6 diagrams)
├── benchmarks/                   # UltraHONK prove/verify logs, Forge gas reports
│
├── zk-private-zakat.tex          # IEEE conference paper (ICIMTech 2026)
└── zk-private-zakat.pdf          # Compiled PDF (6 pages, 33 references)
```

## Smart Contract Architecture

The system follows a modular architecture with ZKTCore as the central orchestrator:

```
ZKTCore (v8)
  ├── ZKVerifier           # verifies UltraHONK proofs (hash anchoring)
  ├── NullifierRegistry    # prevents double-donation (flat mapping)
  ├── ZakatEscrowManager   # fund custody + pool accounting (30-day timelock)
  ├── DonationReceiptNFT   # soulbound receipt SBT (IPFS metadata)
  ├── ProposalManager      # community proposal lifecycle
  ├── VotingManager        # tiered voting (VotingNFT-based)
  ├── ShariaReviewManager  # Sharia council review (Groth16 verifier)
  ├── PoolManager          # general donation pools
  └── MilestoneManager     # milestone-based fund release
```

**Access control**: Role-based (OpenZeppelin AccessControl) with ORGANIZER_ROLE, SHARIA_COUNCIL_ROLE, KYC_ORACLE_ROLE, and MINTER_ROLE.

**v8 E2E Flow** (all executed on-chain):
`createProposal → submitForCommunityVote → castVote → finalizeCommunityVote → createShariaReviewBundle → reviewProposal → finalizeShariaBundle → createCampaignPool → donateZK()`

## ZK Pipeline

The private donation flow:

```
1. Donor connects wallet (wagmi + XellarKit, Sepolia)
2. Selects privacy tier (Private/Semi-Private/Verified-Private/Public)
3. Provides amount + private eligibility inputs
4. Frontend calls /api/generate-proof → nargo execute → bb prove
5. UltraHONK proof generated (246.8ms avg, 8,384 bytes)
6. ZKTCore.donateZK() on Sepolia:
   → ZKVerifier.verify() → true
   → NullifierRegistry.spend() → nullifier marked spent
   → ZakatEscrowManager.donate() → fund transfer + pool accounting
   → DonationReceiptNFT.mint() → soulbound receipt SBT
7. Donor receives SBT receipt (proof of zakat payment)
```

## Frontend Features

- **Wallet connection**: wagmi + XellarKit (multi-wallet support)
- **Privacy tier toggle**: Public / Private switch with contextual notices
- **Quick amount buttons**: 10K, 50K, 100K, 500K IDRX
- **Campaign browsing**: Browse active zakat campaigns
- **Donation flow**: Two-step approval (IDRX.approve → ZKTCore.donate)
- **Certificate modal**: ZakatCertificateModal after successful donation
- **Dashboard**: Donor and organizer dashboards with transaction history
- **Chain enforcement**: Auto-switch to Sepolia with UI warning

## Testing

### Solidity (Foundry)

```bash
cd sc
forge test          # 26 tests passing
forge test --gas-report # full gas report
```

Key test suites:
- `ZKTCoreTest` — 17 tests (donation flow, voting, milestone management)
- `ShariaZKProofTest` — 9 tests (ZK proof submission, quorum verification)

### Noir Circuit

```bash
cd noir-circuits/zkat_eligibility
nargo test          # 3 tests (eligible, ineligible, hawl met)
```

### Frontend

```bash
cd fe
pnpm build          # production build verification
```

## Benchmarks

All benchmark logs are in `benchmarks/`:

| File | Content |
|------|---------|
| `ultrahonk-*.log` | 5 prove runs + 5 verify runs with timings |
| `forge-gas-*.log` | Complete Foundry gas report |
| `sepolia-donatezk-gas.txt` | Actual Sepolia tx gas used |

## Paper

The IEEE conference paper is at `zk-private-zakat.pdf` (6 pages, 33 references).

**Conference**: ICIMTech 2026 (International Conference on Information Management and Technology)

**Scope**: Blockchain Technologies and Fintech

**Section structure**: Introduction, Literature Review, Methodology, Results, Discussion, Conclusion

## Acknowledgments

- **pidi.id** — hackathon organizer
- **BINUS University** — Research Track program
- **Ethereum Jakarta** — technical support and guidance
- **Tawf Labs** — sharia consultation and research implementation

## License

Apache-2.0
