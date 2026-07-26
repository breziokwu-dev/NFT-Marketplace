# NFT Marketplace

A decentralized NFT marketplace built with **Solidity** and **Foundry** that allows users to list, buy, update, and cancel NFT listings while securely withdrawing their proceeds.

## Features

* List ERC721 NFTs for sale
* Buy listed NFTs
* Update listing prices
* Cancel active listings
* Withdraw sale proceeds
* Custom errors for gas-efficient reverts
* Event emission for important state changes
* Comprehensive unit tests with Foundry
* High test coverage

## Tech Stack

* Solidity ^0.8.18
* Foundry
* OpenZeppelin Contracts
* Forge Standard Library

## Project Structure

```
.
├── src/
│   ├── NftMarketplace.sol
│   └── MockNft.sol
├── script/
│   ├── DeployMarketplace.s.sol
│   └── DeployMockNft.s.sol
├── test/
│   └── TestMarketplace.t.sol
└── README.md
```

## Marketplace Workflow

### Listing an NFT

1. Mint an ERC721 NFT.
2. Approve the marketplace contract.
3. Call `listItem()`.
4. The NFT becomes available for purchase.

### Buying an NFT

1. Call `buyItem()` with the exact listing price.
2. Ownership of the NFT is transferred to the buyer.
3. The seller's proceeds are credited to their account.

### Withdrawing Proceeds

1. Seller calls `withdrawProceeds()`.
2. The marketplace transfers the accumulated proceeds.
3. Seller's balance is reset to zero.

## Smart Contract Functions

### Listing

* `listItem()`
* `cancelListing()`
* `updateListing()`

### Purchasing

* `buyItem()`

### Withdrawals

* `withdrawProceeds()`

### View Functions

* `getListing()`
* `getProceeds()`

## Security Considerations

The marketplace includes several safety mechanisms:

* Ownership verification before listing
* Approval verification before listing
* Checks-Effects-Interactions pattern for ETH withdrawals
* Custom errors for gas efficiency
* Event logging for important actions
* Reusable modifiers to reduce duplicated validation logic

## Testing

The project includes unit tests covering:

* Listing NFTs
* Buying NFTs
* Updating listings
* Canceling listings
* Withdrawing proceeds
* Custom error reverts
* Event emission
* Ownership transfers
* ETH accounting

Run all tests:

```bash
forge test
```

Run tests with verbosity:

```bash
forge test -vvvv
```

Generate a coverage report:

```bash
forge coverage
```

## Deployment

Deploy the marketplace:

```bash
forge script script/DeployMarketplace.s.sol --broadcast
```

Deploy the mock NFT:

```bash
forge script script/DeployMockNft.s.sol --broadcast
```

## Future Improvements

* Marketplace fees
* ERC-2981 royalty support
* NFT offers
* Timed auctions
* Listing expiration
* Batch listings
* Frontend integration

## Author

Bryan Eziokwu

GitHub: https://github.com/breziokwu-dev

---

This project was built to strengthen my understanding of ERC721 tokens, marketplace architecture, Solidity best practices, and testing with Foundry.

