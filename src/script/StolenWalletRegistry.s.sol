// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Script.sol";
import "../v1/StolenWalletRegistry.sol";

import "@chainlink/contracts/src/v0.7/tests/MockV3Aggregator.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        StolenWalletRegistry stolenWalletRegistry = new StolenWalletRegistry(mockAggregator.address);

        vm.stopBroadcast();
    }
}
