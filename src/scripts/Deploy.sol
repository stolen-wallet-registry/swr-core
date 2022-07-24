// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import "../v1/StolenWalletRegistry.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        StolenWalletRegistry stolenWalletRegistry = new StolenWalletRegistry("NFT_tutorial", "TUT", "baseUri");

        vm.stopBroadcast();
    }
}
