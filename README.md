# ZK-PZ: Zero-Knowledge Private Zakat

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.31-blue.svg)](https://soliditylang.org/)
[![Next.js](https://img.shields.io/badge/Next.js-16.1.1-black.svg)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/)

Privacy-preserving zakat donations using UltraHONK zero-knowledge proofs on Ethereum Sepolia. Enables donors to contribute zakat with cryptographic anonymity while maintaining verifiable Sharia compliance and institutional accountability.

- **Testnet**: [ziswaf.tawf.foundation](https://ziswaf.tawf.foundation)
- **Paper**: `zkdid.pdf` (IEEE conference format, 6 pages, 29 references)

## Architecture

```
Donor Frontend (Next.js 15 PWA + wagmi/XellarKit)
    │  wallet connect, tier select, private inputs
    ▼
Off-Chain Proving (Noir + Barretenberg v4.2.1)
    │  nargo compile → nargo execute → bb prove UltraHONK
    │  29 ACIR opcodes, 262ms avg, 8,384 bytes proof
    ▼
Ethereum Sepolia (16 Solidity contracts)
    │  ZKVerifier.verify() → ZKTCore.donateZK()
    │  → NullifierRegistry.spend() → ZakatEscrowManager.donate()
    │  → DonationReceiptNFT.mint() → receipt SBT
    ▼
Recipient receives soulbound NFT receipt
```

## Deployed on Sepolia

| Contract | Address |
|----------|---------|
| ZKTCore (v5) | `0xaAebE1f3a1Ae1ecD5BCf11Ae499C5c75d081C04A` |
| ZKVerifier | `0x50471F33ed68167740dACDc7Be3DEe465Fa9ca66` |
| NullifierRegistry | `0x034f31ECf82f5A3dE0Db2c16fA48E51CCA34d018` |
| MockIDRX | `0x856d02e138f8707cA90346c657A537e8C67475E0` |
| DonationReceiptNFT | `0xB17c9849Ef7D21C7C771128bE7dd852f7d5298a9` |

End-to-end donation verified at [tx 0xdfaca7...eb9f](https://sepolia.etherscan.io/tx/0xdfaca7b413b29f57242cb4f49f4f35a11aab4953f47b806ed939370e9b36eb9f), block 10,844,400, consuming 4.2M gas.

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
| Proof generation (avg) | 261.8 ms |
| Proof verification (avg) | 13.0 ms |
| Proof size | 8,384 bytes |

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
├── zkdid.tex               # IEEE conference paper
└── zkdid.pdf               # Compiled PDF (6 pages)
```

## Acknowledgments

- **Ethereum Jakarta** — technical support and guidance
- **Tawf Labs** — sharia consultation and research implementation
- **BINUS University** — hackathon project support

## License

Apache-2.0
