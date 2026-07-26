// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";


/// @title NFT Marketplace
/// @author Bryan Eziokwu (@breziokwu-dev)
/// @notice A decentralized marketplace for listing and trading ERC721 NFTs.
/// @dev Sellers receive proceeds which can be withdrawn at any time.
contract NftMarketplace {

    error PriceMustBeAboveZero();
    error AlreadyListed();
    error NotOwner();
    error NotApprovedForMarketplace();
    error NotListed();
    error PriceNotMet();
    error NoProceeds();
    error TransferFailed();
    error NotSeller();

    /// @notice Represents an NFT listed for sale.
    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ProceedsWithdrawn(address indexed seller, uint256 amount);
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event ItemUpdated(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;

    /// @notice Ensures an NFT is currently listed for sale.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The NFT's token ID.
    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(listing.seller == address(0)) {
            revert NotListed();
        }
        _;
    }

    /// @notice Ensures the caller is the seller of the listing.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The NFT's token ID.
    /// @param spender The address attempting to perform the action.
    modifier isSeller(address nftAddress, uint256 tokenId, address spender) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.seller != msg.sender) {
            revert NotSeller();
        }
        _;
    }
    
    /// @notice Lists an NFT for sale on the marketplace.
    /// @dev The NFT owner must approve this marketplace before listing.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the NFT to list.
    /// @param price The sale price in wei.
    function listItem(address nftAddress, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftAddress);

        if (price == 0) {
            revert PriceMustBeAboveZero();
        }

        if (s_listings[nftAddress][tokenId].seller != address(0)) {
            revert AlreadyListed();
        }

        address owner = nft.ownerOf(tokenId);

        if (owner != msg.sender) {
            revert NotOwner();
        }

        bool approvedForToken = nft.getApproved(tokenId) == address(this);
        bool approvedForAll = nft.isApprovedForAll(owner, address(this));

        if (!approvedForToken && !approvedForAll) {
            revert NotApprovedForMarketplace();
        }

        s_listings[nftAddress][tokenId] = Listing({
            price: price,
            seller: msg.sender
        });

        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /// @notice Purchases a listed NFT.
    /// @dev The buyer must send the exact listing price.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the NFT to purchase.
    function buyItem(address nftAddress, uint256 tokenId) external payable isListed(nftAddress, tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(msg.value != listing.price) {
            revert PriceNotMet();
        }
        s_proceeds[listing.seller] += listing.price;
        delete s_listings[nftAddress][tokenId];
        IERC721(nftAddress).safeTransferFrom(listing.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listing.price);
        
    }

    /// @notice Withdraws the caller's accumulated sale proceeds.
    /// @dev Uses the Checks-Effects-Interactions pattern to prevent reentrancy.
    function withdrawProceeds() external {
        if(s_proceeds[msg.sender] == 0) {
            revert NoProceeds();
        }

        uint256 amount = s_proceeds[msg.sender];
        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }

        emit ProceedsWithdrawn(msg.sender, amount);
    }

    /// @notice Cancels an active NFT listing.
    /// @dev Only the seller can cancel a listing.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the NFT whose listing will be removed.
    function cancelListing(address nftAddress, uint256 tokenId) external isListed(nftAddress, tokenId) isSeller(nftAddress, tokenId, msg.sender) {
        delete s_listings[nftAddress][tokenId];

        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    /// @notice Updates the price of an existing listing.
    /// @dev Only the seller can update the listing price.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the listed NFT.
    /// @param newPrice The new listing price in wei.
    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice) public isListed(nftAddress, tokenId) isSeller(nftAddress, tokenId, msg.sender) {
        if(newPrice == 0) {
            revert PriceMustBeAboveZero();
        }

        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemUpdated(msg.sender, nftAddress, tokenId, newPrice);

    }

    /// @notice Returns the listing details for an NFT.
    /// @param nftAddress The address of the ERC721 contract.
    /// @param tokenId The NFT's token ID.
    /// @return The Listing struct containing the seller and price.
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }

    /// @notice Returns the amount of proceeds available for a seller to withdraw.
    /// @param seller The seller's address.
    /// @return The seller's withdrawable proceeds in wei.
    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }

}