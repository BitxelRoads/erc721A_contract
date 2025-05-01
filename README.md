# Bitxel Roads Smart Contract

## Overview
Bitxel Roads is an ERC721A-based NFT collection with a total supply of 4,444 tokens. The contract implements a phased minting system with different tiers of access and pricing.

## Contract Details

### Key Features
- Total Supply: 4,444 NFTs
- Phased Minting System:
  - OG Phase: 444 NFTs (Free)
  - GTD Phase: NFTs (Free)
  - FCFS Phase: NFTs (Paid)
  - Public Phase: Remaining NFTs (Paid)
- Royalty System: 5% default royalty
- Reveal Mechanism with Random Offset
- Time-based Phase Management

### Minting Phases
1. **OG Phase**
   - Supply: 444 NFTs
   - Price: Free
   - Limit: 1 NFT per wallet
   - Requires OG List access

2. **GTD Phase**
   - Supply: 1,000 NFTs
   - Price: Free
   - Limit: 1 NFT per wallet
   - Requires GTD List access

3. **FCFS Phase**
   - Supply: 500 NFTs
   - Price: Configurable
   - Limit: 3 NFTs per wallet
   - Requires FCFS List access

4. **Public Phase**
   - Supply: Remaining NFTs
   - Price: Configurable
   - Limit: 4 NFTs per wallet
   - Open to all

### Technical Features
- Built on ERC721A for gas-efficient batch minting
- Implements ERC2981 for royalty support
- Uses OpenZeppelin's security features:
  - Ownable
  - Pausable
  - ReentrancyGuard
- Time-based phase management (12-hour duration per phase)
- Random reveal mechanism using blockhash
- Configurable pricing for FCFS and Public phases

## Contract Address
The contract is deployed on the Sepolia testnet.

## Security Features
- Reentrancy protection
- Pausable functionality
- Access control through Ownable
- Phase-based access control
- Supply limit enforcement
- Wallet limit enforcement

## Development
### Prerequisites
- Node.js
- Hardhat or Truffle
- Solidity ^0.8.24

### Dependencies
```json
{
  "@openzeppelin/contracts": "^5.0.0",
  "erc721a": "^4.3.0"
}
```

## License
MIT License

## Author
Joalseca
