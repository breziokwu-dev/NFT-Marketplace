// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {MockNft} from "src/MockNft.sol";
import {DeployMockNft} from "script/DeployMockNft.s.sol";

contract TestMockNft is Test {
    DeployMockNft public deployer;
    MockNft public mockNft;
    address public USER = makeAddr("User");

    function setUp() public {
        deployer = new DeployMockNft();
        mockNft = deployer.run();
    }

    function testNameAndSymbolIsCorrect() public view {
        assertEq(mockNft.name(), "Mock NFT");
        assertEq(mockNft.symbol(), "MNFT");
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        mockNft.mintNft();
        assertEq(mockNft.balanceOf(USER), 1);
        assertEq(mockNft.ownerOf(0), USER);
    }

    function testBalanceIncreasesAsMoreNftIsMinted() public {
        vm.startPrank(USER);
        mockNft.mintNft();
        mockNft.mintNft();
        vm.stopPrank();
        assertEq(mockNft.balanceOf(USER), 2);
    }

    function testTokenIdsIncrement() public {
        vm.startPrank(USER);
        mockNft.mintNft();
        mockNft.mintNft();
        vm.stopPrank();
        assertEq(mockNft.ownerOf(0), USER);
        assertEq(mockNft.ownerOf(1), USER);
    }

    function testDifferentUsersOwnTheirOwnNfts() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        vm.prank(alice);
        mockNft.mintNft();

        vm.prank(bob);
        mockNft.mintNft();

        assertEq(mockNft.ownerOf(0), alice);
        assertEq(mockNft.ownerOf(1), bob);
        assertEq(mockNft.balanceOf(alice), 1);
        assertEq(mockNft.balanceOf(bob), 1);
}
}