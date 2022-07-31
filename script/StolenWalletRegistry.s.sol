// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@std/Script.sol";
import "../src/v1/StolenWalletRegistry.sol";
import "../src/v1/tests/MockV3Aggregator.sol";

import "forge-std/console.sol";

contract DeployStollenWalletRegistry is Script {
    function run() external {
        vm.startBroadcast();
        MockV3Aggregator mockAggregator = new MockV3Aggregator(8, 155996954280);
        vm.stopBroadcast();

        vm.startBroadcast();

        StolenWalletRegistry stolenWalletRegistry = new StolenWalletRegistry(address(mockAggregator));
        vm.stopBroadcast();
    }
}
