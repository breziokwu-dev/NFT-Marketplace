// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNft is ERC721 {
    uint256 private s_tokenCounter;

    constructor() ERC721("Mock NFT", "MNFT") {}

    function mintNft() public returns(uint256 tokenId) {
        tokenId = s_tokenCounter;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }
}