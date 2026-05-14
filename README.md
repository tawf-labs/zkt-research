# ZK-PZ: Zero-Knowledge Private Zakat

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.31-blue.svg)](https://soliditylang.org/)
[![Next.js](https://img.shields.io/badge/Next.js-16.1.1-black.svg)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/)

Privacy-preserving zakat donations using UltraHONK zero-knowledge proofs on Ethereum Sepolia. Enables donors to contribute zakat with cryptographic anonymity while maintaining verifiable Sharia compliance and institutional accountability.

- **Testnet**: [ziswaf.tawf.foundation](https://ziswaf.tawf.foundation)
- **Paper**: `zk-private-zakat.pdf` (IEEE conference format, 6 pages, 33 references)
- **Authors**: Muhammad Zidan Fatonie, Alexander Agung Santoso Gunawan (BINUS University)

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

## Deployed on Sepolia (Fresh — 17 Contracts)

| Contract | Address |
|----------|---------|
| ZKTCore (v6) | `0x1da6328142ccc7939d2150451e664b0d0bd7d35a` |
| ZKVerifier | `0x50471F33ed68167740dACDc7Be3DEe465Fa9ca66` |
| NullifierRegistry | `0x7eC9360f46158504f48b616147d7c3cd1dfB617b` |
| MockIDRX | `0x18f54ad14a7a4bf9e10b70899d302aea1e545d4b` |
| DonationReceiptNFT | `0x10310da107719fec1b2ee3f35904c3205071157d` |
| ZakatEscrowManager | `0xe7aa1d224e74e2fcdfb0fb8a9f65f8f6ec891fc6` |
| VotingNFT | `0xf76b4b19866bf182de8e4d246b5d518ff15cb165` |
| Groth16Verifier | `0x3d46fbd717ebc07ddbfbd9c5811f552ded0f1b17` |
| ProposalManager | `0x427af887b3abe24784bc0cb119500d3bb4c2d2c0` |
| VotingManager | `0xa733fd83d64173cc7d03627f1c526b18b06fbe94` |
| ShariaReviewManager | `0x364835295d25b157c8fad75f289ad6cc9335216b` |
| PoolManager | `0x01f89c2ae4be7ff35b02867e67780c26e56a16c2` |
| MilestoneManager | `0x5a9e348a10709fa7ab29de17f664b4366f9e8c96` |
| OrganizerNFT | `0xe4346b881d4ef8c0489e34df2ede766f4b39e8ce` |
| ParticipationTracker | `0xbcfbb72b538afd273c34a99646724cd29a4bc609` |
| HonkVerifier (slim) | `0x90fccbb10aa07deb1ac15a690b24dfded81e8ddc` |

End-to-end donation verified at [tx 0xdfaca7...eb9f](https://sepolia.etherscan.io/tx/0xdfaca7b413b29f57242cb4f49f4f35a11aab4953f47b806ed939370e9b36eb9f), block 10,844,400, consuming 545K gas.

## Quick Start

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
```

## Circuit Performance

| Metric | Value |
|--------|-------|
| ACIR opcodes | 29 |
| Brillig opcodes | 44 |
| Proof generation (avg) | 281.6 ms |
| Proof generation (min) | 244.0 ms |
| Proof generation (max) | 295.0 ms |
| Proof verification (avg) | 13.4 ms |
| Proof size | 8,384 bytes |
| Verification key size | 1,888 bytes |

## Project Structure

```
├── fe/                     # Next.js 15 PWA frontend
│   ├── app/                # App router pages
│   ├── components/         # React components (donations, wallet, UI)
│   ├── hooks/              # useWallet, usePrivateDonation
│   └── lib/                # ABIs, config, ZK integration
├── sc/                     # Solidity smart contracts
│   ├── src/DAO/            # ZKTCore, verifiers, managers
│   ├── src/tokens/         # MockIDRX, DonationReceiptNFT, VotingNFT
│   ├── script/             # Deploy scripts, proof generator
│   └── test/               # Foundry tests
├── noir-circuits/          # Noir ZK circuits
│   └── zkat_eligibility/   # Nisab + hawl + nullifier verification
├── docs/diagrams/          # PlantUML sources + generated PNGs
├── benchmarks/             # UltraHONK prove/verify logs, Forge gas reports
├── zk-private-zakat.tex    # IEEE conference paper
└── zk-private-zakat.pdf    # Compiled PDF (6 pages)
```

## Acknowledgments

- **Ethereum Jakarta** — technical support and guidance
- **Tawf Labs** — sharia consultation and research implementation
- **BINUS University** — hackathon project support

## License

Apache-2.0
