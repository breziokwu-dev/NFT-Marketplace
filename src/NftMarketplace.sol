// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftMarketplace {

    error PriceMustBeAboveZero();
    error AlreadyListed();
    error NotOwner();
    error NotApprovedForMarketplace();
    error NotListed();
    error PriceNotMet();
    error NoProceeds();
    error TransferFailed();

    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ProceedsWithdrawn(address indexed seller, uint256 amount);

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;
    
    function listItem(address nftAddress, uint256 tokenId, uint256 price) public {
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

    function buyItem(address nftAddress, uint256 tokenId) public payable {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(listing.seller == address(0)) {
            revert NotListed();
        }
        if(msg.value != listing.price) {
            revert PriceNotMet();
        }
        s_proceeds[listing.seller] += listing.price;
        delete s_listings[nftAddress][tokenId];
        IERC721(nftAddress).safeTransferFrom(listing.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listing.price);
        
    }

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

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }

}