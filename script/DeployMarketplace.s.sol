// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {NftMarketplace} from "src/NftMarketplace.sol";

contract DeployMarketplace is Script {

    function run() public returns(NftMarketplace) {
        vm.startBroadcast();
        NftMarketplace nftMarketplace = new NftMarketplace();
        vm.stopBroadcast();
        return nftMarketplace;
    }
}