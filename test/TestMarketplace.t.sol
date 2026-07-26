// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {NftMarketplace} from "src/NftMarketplace.sol";
import {DeployMarketplace} from "script/DeployMarketplace.s.sol";
import {MockNft} from "src/MockNft.sol";
import {DeployMockNft} from "script/DeployMockNft.s.sol";

contract TestMarketplace is Test {
    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ProceedsWithdrawn(address indexed seller, uint256 amount);
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event ItemUpdated(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    DeployMockNft public deploy;
    MockNft public mockNft;

    DeployMarketplace public deployer;
    NftMarketplace public market;
    address public USER = makeAddr("User");
    address public USER1 = makeAddr("User1");
    uint256 public constant TOKEN_ID = 0;
    uint256 public constant PRICE = 1 ether;
    uint256 public constant NEW_PRICE = 2 ether;

    function setUp() public {
        deploy = new DeployMockNft();
        mockNft = deploy.run();

        deployer = new DeployMarketplace();
        market = deployer.run();
        
        vm.deal(USER1, 10 ether);
        vm.deal(USER, 10 ether);
        
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
        vm.startPrank(USER1);
        vm.expectRevert(NftMarketplace.NotOwner.selector);
        market.listItem(address(mockNft), TOKEN_ID, PRICE);
        vm.stopPrank();
    }

    modifier listItem() {
        vm.prank(USER);
        market.listItem(address(mockNft), TOKEN_ID, PRICE);
        _;
    }

    function testCanBuyItem() public listItem {
        vm.prank(USER1);
        market.buyItem{value: PRICE}(address(mockNft), TOKEN_ID);
        NftMarketplace.Listing memory listing = market.getListing(address(mockNft), TOKEN_ID);

        assertEq(listing.seller, address(0));
        assertEq(listing.price, 0);
        assertEq(mockNft.ownerOf(TOKEN_ID), USER1);
        assertEq(market.getProceeds(USER), PRICE);
        
    }

    function testRevertsIfNotListed() public {
        vm.prank(USER1);
        vm.expectRevert(NftMarketplace.NotListed.selector);
        market.buyItem{value: PRICE}(address(mockNft), TOKEN_ID);
    }

    function testRevertsIfUnderPaid() public listItem {
        vm.prank(USER1);
        vm.expectRevert(NftMarketplace.PriceNotMet.selector);
        market.buyItem{value: 0}(address(mockNft), TOKEN_ID);
    }

    function testRevertsIfOverPaid() public listItem{
        vm.prank(USER1);
        vm.expectRevert(NftMarketplace.PriceNotMet.selector);
        market.buyItem{value: 2}(address(mockNft), TOKEN_ID);
    }

    function testListingIsDeletedAfterPurchase() public listItem {
        vm.prank(USER1);
        market.buyItem{value: PRICE}(address(mockNft), TOKEN_ID);
        NftMarketplace.Listing memory listing = market.getListing(address(mockNft), TOKEN_ID);

        assertEq(listing.seller, address(0));
        assertEq(listing.price, 0);
    }

    function testSellersProceedsIncrease() public listItem {
        uint256 initialBalance = market.getProceeds(USER);
        vm.prank(USER1);
        market.buyItem{value: PRICE}(address(mockNft), TOKEN_ID);
        uint256 finalBalance = market.getProceeds(USER);
        assertEq(finalBalance, initialBalance + PRICE);
    }

    function testOwnershipTransfersToBuyer() public listItem {
        vm.prank(USER1);
        market.buyItem{value: PRICE}(address(mockNft), TOKEN_ID);
        assertEq(mockNft.ownerOf(TOKEN_ID), USER1);
    }

    function testItemBoughtEventIsEmitted() public listItem {
        vm.expectEmit(true, true, true, true);
        emit ItemBought(USER1, address(mockNft), TOKEN_ID, PRICE);
        vm.prank(USER1);
        market.buyItem{value: PRICE}(address(mockNft), TOKEN_ID);     
    }

    modifier boughtItem() {
        vm.prank(USER1);
        market.buyItem{value: PRICE}(address(mockNft), TOKEN_ID);
        _;       
    }

    function testCanWithdrawProceeds() public listItem boughtItem {
        uint256 proceeds = market.getProceeds(USER);
        vm.prank(USER);
        market.withdrawProceeds();

        assertEq(proceeds, PRICE);
        assertEq(market.getProceeds(USER), 0);
    }

    function testRevertsIfNoProceeds() public {
        vm.prank(USER);
        vm.expectRevert(NftMarketplace.NoProceeds.selector);
        market.withdrawProceeds();
    }

    function testSellerReceivesEther() public listItem boughtItem {
        uint256 initialBalance = address(USER).balance;
        uint256 proceeds = market.getProceeds(USER);
        vm.prank(USER);
        market.withdrawProceeds();
        uint256 finalBalance = address(USER).balance;
        assertEq(finalBalance , initialBalance + proceeds);
    }

    function testEventIsEmittedOnWithdraw() public listItem boughtItem {
        uint256 proceeds = market.getProceeds(USER);
        vm.expectEmit(true, false, false,true);
        emit ProceedsWithdrawn(USER, proceeds);
        vm.prank(USER);
        market.withdrawProceeds();
    }

    function testProceedsResetAfterwithdraw() public listItem boughtItem {
        vm.prank(USER);
        market.withdrawProceeds();
        assertEq(market.getProceeds(USER) , 0);
    }

    function testSellerCannotWithdrawTwice() public listItem boughtItem {
        vm.prank(USER);
        market.withdrawProceeds();


        vm.expectRevert(NftMarketplace.NoProceeds.selector);
        vm.prank(USER);
        market.withdrawProceeds();
    }

    function testCanCancelListing() public listItem {
        vm.prank(USER);
        market.cancelListing(address(mockNft), TOKEN_ID);

        NftMarketplace.Listing memory listing =
            market.getListing(address(mockNft), TOKEN_ID);

        assertEq(listing.seller, address(0));
        assertEq(listing.price, 0);
    }

    function testCancelRevertsIfNotListed() public {
        vm.prank(USER);

        vm.expectRevert(NftMarketplace.NotListed.selector);
        market.cancelListing(address(mockNft), TOKEN_ID);
    }

    function testCancelRevertsIfNotSeller() public listItem {
        vm.prank(USER1);

        vm.expectRevert(NftMarketplace.NotSeller.selector);
        market.cancelListing(address(mockNft), TOKEN_ID);
    }

    function testCancelEmitsEvent() public listItem {
        vm.expectEmit(true, true, true, false);

        emit ItemCanceled(USER, address(mockNft), TOKEN_ID);

        vm.prank(USER);
        market.cancelListing(address(mockNft), TOKEN_ID);
    }

    function testCanUpdateListing() public listItem {
        vm.prank(USER);
        market.updateListing(address(mockNft), TOKEN_ID, NEW_PRICE);

        NftMarketplace.Listing memory listing =
            market.getListing(address(mockNft), TOKEN_ID);

        assertEq(listing.price, NEW_PRICE);
        assertEq(listing.seller, USER);
    }

    function testUpdateRevertsIfPriceIsZero() public listItem {
        vm.prank(USER);

        vm.expectRevert(NftMarketplace.PriceMustBeAboveZero.selector);
        market.updateListing(address(mockNft), TOKEN_ID, 0);
    }

    function testUpdateRevertsIfNotListed() public {
        vm.prank(USER);

        vm.expectRevert(NftMarketplace.NotListed.selector);
        market.updateListing(address(mockNft), TOKEN_ID, NEW_PRICE);
    }

    function testUpdateRevertsIfNotSeller() public listItem {
        vm.prank(USER1);

        vm.expectRevert(NftMarketplace.NotSeller.selector);
        market.updateListing(address(mockNft), TOKEN_ID, NEW_PRICE);
    }


    function testUpdateEmitsEvent() public listItem {
        vm.expectEmit(true, true, true, true);

        emit ItemUpdated(USER, address(mockNft), TOKEN_ID, NEW_PRICE);

        vm.prank(USER);
        market.updateListing(address(mockNft), TOKEN_ID, NEW_PRICE);
    }

    function testBuyUsesUpdatedPrice() public listItem {
        vm.prank(USER);
        market.updateListing(address(mockNft), TOKEN_ID, NEW_PRICE);

        vm.deal(USER1, NEW_PRICE);

        vm.prank(USER1);
        market.buyItem{value: NEW_PRICE}(address(mockNft), TOKEN_ID);

        assertEq(mockNft.ownerOf(TOKEN_ID), USER1);
        assertEq(market.getProceeds(USER), NEW_PRICE);
    }
}