# Versebit - Poetry NFT Registry 🗂️

A blockchain-based smart contract system for providing immutable proof-of-authorship for poetry and verse through non-fungible tokens on the Stacks blockchain.

## Overview

Versebit revolutionizes poetry ownership and attribution by creating an immutable, decentralized registry where poets can mint NFTs representing their original works. Each poem is permanently recorded on the blockchain with cryptographic proof of authorship, timestamp, and content integrity.

## Key Features

### 🔏 Immutable Proof-of-Authorship
- Cryptographic proof of poem ownership and creation time
- Tamper-proof storage of poetry metadata and content hashes
- Permanent record of original authorship on the blockchain

### 📝 Poetry NFT Minting
- Transform poems into unique NFT tokens
- Support for various poetry formats and metadata
- Royalty mechanisms for secondary sales and licensing

### 🎨 Content Integrity Verification
- SHA-256 hash verification of original poem content
- Protection against plagiarism and unauthorized modifications
- Timestamped proof of creation for copyright purposes

### 👤 Poet Profile Management
- Comprehensive poet profiles with portfolio tracking
- Reputation systems based on community engagement
- Collections and anthology management

## Technical Architecture

The system consists of two main smart contracts:

1. **Poetry Registry Contract** - Core NFT minting, ownership tracking, and metadata management
2. **Authorship Verification Contract** - Proof-of-authorship verification, content hashing, and dispute resolution

## Smart Contract Features

### Poetry Registry Contract
- NFT token creation and management
- Poem metadata storage and retrieval
- Ownership transfer and trading mechanisms
- Royalty distribution systems
- Poetry collection management

### Authorship Verification Contract
- Content hash verification and validation
- Plagiarism detection and reporting
- Timestamp-based proof of creation
- Author verification and credential systems
- Dispute resolution mechanisms

## Use Cases

- **Independent Poets**: Establish ownership and copyright of original works
- **Poetry Publishers**: Verify authenticity and ownership before publication
- **Literary Competitions**: Ensure original submissions and prevent plagiarism
- **Academic Research**: Track poetry evolution and influence networks
- **Digital Collections**: Create and manage curated poetry NFT collections
- **Licensing & Rights**: Facilitate poem licensing for commercial use

## NFT Metadata Structure

Each poetry NFT contains:
- **Title**: Poem title and subtitle
- **Content Hash**: SHA-256 hash of the complete poem text
- **Author**: Verified poet's blockchain address
- **Creation Timestamp**: Immutable timestamp of minting
- **Genre/Tags**: Classification and discovery metadata
- **License Terms**: Usage rights and permissions
- **Provenance**: Complete ownership and transfer history

## Security Features

- Content hash verification prevents tampering
- Multi-signature support for collaborative works
- Time-locked publishing for delayed releases
- Burn mechanisms for privacy or retraction
- Emergency pause controls for system maintenance

## Getting Started

### Prerequisites
- Clarinet CLI
- Stacks Wallet
- Node.js and npm

### Installation
```bash
git clone [repository-url]
cd versebit
npm install
```

### Testing
```bash
clarinet check
npm test
```

### Deployment
```bash
clarinet deploy
```

## Poetry Formats Supported

- Traditional verse forms (sonnets, haikus, etc.)
- Free verse and contemporary poetry
- Collaborative and multi-author works
- Poetry cycles and sequential collections
- Multilingual and translation works

## Community Features

- Poet discovery and networking
- Community curation and featuring
- Poetry challenges and competitions
- Reader engagement and feedback systems
- Cross-platform integration with poetry platforms

## Documentation

Detailed documentation for each contract and their functions can be found in the respective contract files in the `contracts/` directory.

## Contributing

We welcome contributions from poets, developers, and literary enthusiasts. Please see our contribution guidelines for more information.

## License

This project is open source and available under the MIT License.

## Support

For technical support, poetry submissions, or partnership inquiries, please contact the development team.

---

**Empowering poets through blockchain technology and immutable proof-of-authorship** ✍️📜
