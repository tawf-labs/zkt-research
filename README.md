# ZK-PZ: Zero-Knowledge Private Zakat

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.31-blue.svg)](https://soliditylang.org/)
[![Next.js](https://img.shields.io/badge/Next.js-16.1.1-black.svg)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/)
[![Noir](https://img.shields.io/badge/Noir-1.0.0--beta.21-purple.svg)](https://noir-lang.org/)

Privacy-preserving zakat donations using UltraHONK zero-knowledge proofs on Ethereum Sepolia. Enables donors to contribute zakat with cryptographic anonymity while maintaining verifiable Sharia compliance and institutional accountability.

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

ZK-PZ addresses a critical gap in blockchain-based zakat systems: all existing platforms expose complete donor-recipient transaction records on public ledgers, violating Islamic principles of dignity preservation (nafs protection in maqasid al-shariah).

**Key features:**
- **Noir circuit** (29 ACIR opcodes) encoding nisab + hawl + pedersen nullifier verification
- **UltraHONK proofs** generated via Barretenberg v4.2.1 (281.6ms avg)
- **On-chain verification** through ZKVerifier with nullifier-based double-donation prevention
- **17 Solidity contracts** deployed on Ethereum Sepolia testnet
- **Next.js 15 PWA** frontend with wagmi/XellarKit wallet connectivity
- **Privacy tier toggle** supporting Private, Semi-Private, Verified-Private, and Public modes

## Architecture

```
Donor Frontend (Next.js 15 PWA + wagmi/XellarKit)
    │  wallet connect, tier select, private inputs
    ▼
Off-Chain Proving (Noir + Barretenberg v4.2.1)
    │  nargo compile → nargo execute → bb prove UltraHONK
    │  29 ACIR opcodes, 281.6ms avg prove, 13.4ms avg verify, 8,384 bytes proof
    ▼
Ethereum Sepolia (17 Solidity contracts)
    │  ZKVerifier.verify() → ZKTCore.donateZK()
    │  → NullifierRegistry.spend() → ZakatEscrowManager.donate()
    │  → DonationReceiptNFT.mint() → receipt SBT to donor
    ▼
Donor receives soulbound NFT receipt (proof of zakat payment)
```

## Deployed Contracts (Sepolia)

Fresh deployment — all 17 contracts verified onchain.

| Contract | Address |
|----------|---------|
| ZKTCore (v6) | `0x1da6328142ccc7939d2150451e664b0d0bd7d35a` |
| ZKVerifier | `0x50471F33ed68167740dACDc7Be3DEe465Fa9ca66` |
| NullifierRegistry | `0x7eC9360f46158504f48b616147d7c3cd1dfB617b` |
| MockIDRX | `0x18f54ad14a7a4bf9e10b70899d302aea1e545d4b` |
| DonationReceiptNFT | `0x10310da107719fec1b2ee3f35904c3205071157d` |
| ZakatEscrowManager | `0xe7aa1d224e74e2fcdfb0fb8a9f65f8f6ec891fc6` |
| ProposalManager | `0x427af887b3abe24784bc0cb119500d3bb4c2d2c0` |
| VotingManager | `0xa733fd83d64173cc7d03627f1c526b18b06fbe94` |
| ShariaReviewManager | `0x364835295d25b157c8fad75f289ad6cc9335216b` |
| PoolManager | `0x01f89c2ae4be7ff35b02867e67780c26e56a16c2` |
| MilestoneManager | `0x5a9e348a10709fa7ab29de17f664b4366f9e8c96` |
| VotingNFT | `0xf76b4b19866bf182de8e4d246b5d518ff15cb165` |
| OrganizerNFT | `0xe4346b881d4ef8c0489e34df2ede766f4b39e8ce` |
| ParticipationTracker | `0xbcfbb72b538afd273c34a99646724cd29a4bc609` |
| Groth16Verifier | `0x3d46fbd717ebc07ddbfbd9c5811f552ded0f1b17` |
| HonkVerifier (slim) | `0x90fccbb10aa07deb1ac15a690b24dfded81e8ddc` |

End-to-end donation verified at [tx 0xdfaca7...eb9f](https://sepolia.etherscan.io/tx/0xdfaca7b413b29f57242cb4f49f4f35a11aab4953f47b806ed939370e9b36eb9f), block 10,844,400, consuming 545K gas.

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
| Proof generation (avg) | 281.6 ms |
| Proof generation (min) | 244.0 ms |
| Proof generation (max) | 295.0 ms |
| Proof verification (avg) | 13.4 ms |
| Proof size | 8,384 bytes |
| Verification key size | 1,888 bytes |

On-chain gas consumption (Foundry gas report):

| Function | Gas (avg) |
|----------|-----------|
| `ZKTCore.donate()` | 490,187 |
| `ZKTCore.donateZK()` (e2e) | 545,146 |
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
│       ├── abi.ts                # All 17 contract addresses + ABIs
│       └── aztec-private-donation.ts  # Proof generation pipeline
│
├── sc/                           # Solidity smart contracts
│   ├── src/DAO/
│   │   ├── ZKTCore.sol           # Main orchestrator (donateZK, donate, castVote)
│   │   ├── NullifierRegistry.sol # Nullifier tracking for double-donation prevention
│   │   ├── core/                 # ProposalManager, VotingManager, ShariaReviewManager,
│   │   │                          PoolManager, ZakatEscrowManager, MilestoneManager
│   │   └── verifiers/
│   │       └── HonkVerifier.sol  # IHonkVerifier interface
│   ├── src/tokens/               # MockIDRX, DonationReceiptNFT, VotingNFT, OrganizerNFT
│   ├── src/participants/         # ParticipationTracker
│   ├── script/
│   │   ├── DeployZKT.s.sol       # Full deployment script (17 contracts)
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
ZKTCore (v6)
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

## ZK Pipeline

The private donation flow:

```
1. Donor connects wallet (wagmi + XellarKit, Sepolia)
2. Selects privacy tier (Private/Semi-Private/Verified-Private/Public)
3. Provides amount + private eligibility inputs
4. Frontend calls /api/generate-proof → nargo execute → bb prove
5. UltraHONK proof generated (281.6ms, 8,384 bytes)
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
