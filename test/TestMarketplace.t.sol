// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {NftMarketplace} from "src/NftMarketplace.sol";
import {DeployMarketplace} from "script/DeployMarketplace.s.sol";
import {MockNft} from "src/MockNft.sol";
import {DeployMockNft} from "script/DeployMockNft.s.sol";

contract TestMarketplace is Test {
    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    DeployMockNft public deploy;
    MockNft public mockNft;

    DeployMarketplace public deployer;
    NftMarketplace public market;
    address public USER = makeAddr("User");
    uint256 public constant TOKEN_ID = 0;
    uint256 public constant PRICE = 1 ether;

    function setUp() public {
        deploy = new DeployMockNft();
        mockNft = deploy.run();

        deployer = new DeployMarketplace();
        market = deployer.run();

        vm.startPrank(USER);

        mockNft.mintNft();
        mockNft.setApprovalForAll(address(market), true);
        mockNft.approve(address(market), TOKEN_ID);

        vm.stopPrank();
        
    }

    function testCanListItem() public {
        vm.prank(USER);
        market.listItem(address(mockNft), TOKEN_ID, PRICE);

        NftMarketplace.Listing memory listing = market.getListing(address(mockNft), TOKEN_ID);

        assertEq(listing.price, PRICE);
        assertEq(listing.seller, USER);
    }

    function testEventIsEmitted() public {
        vm.expectEmit(true, true, true, true);
        emit ItemListed(USER, address(mockNft), TOKEN_ID, PRICE);
        vm.prank(USER);
        market.listItem(address(mockNft), TOKEN_ID, PRICE);

    }

    function testRevertsIfPriceIsZero() public {
        vm.expectRevert(NftMarketplace.PriceMustBeAboveZero.selector);
        vm.prank(USER);
        market.listItem(address(mockNft), TOKEN_ID, 0);       
    }

    function testRevertIfNftIsAlreadyListed() public {
        vm.startPrank(USER);
        market.listItem(address(mockNft), TOKEN_ID, PRICE);
        vm.expectRevert(NftMarketplace.AlreadyListed.selector);
        market.listItem(address(mockNft), TOKEN_ID, PRICE);
        vm.stopPrank();
    }

    function testRevertsIfMarketplaceNotApproved() public {
        vm.startPrank(USER);
        mockNft.approve(address(0), TOKEN_ID);
        mockNft.setApprovalForAll(address(market), false);
        vm.expectRevert(NftMarketplace.NotApprovedForMarketplace.selector);
        market.listItem(address(mockNft), TOKEN_ID, PRICE);  
        vm.stopPrank();      
    }

    function testOnlyOwnerCanList() public {
        address USER1 = makeAddr("User1");
        vm.startPrank(USER1);
        vm.expectRevert(NftMarketplace.NotOwner.selector);
        market.listItem(address(mockNft), TOKEN_ID, PRICE);
        vm.stopPrank();
    }

}