// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockNft} from "src/MockNft.sol";

contract DeployMockNft is Script{
    
    function run() public returns(MockNft) {
        vm.startBroadcast();
        MockNft mockNft = new MockNft();
        vm.stopBroadcast();
        return mockNft;
    }

}

