// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@std/Script.sol";
import "@chainlink/contracts/src/v0.7/tests/MockV3Aggregator.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        StolenWalletRegistry stolenWalletRegistry = new StolenWalletRegistry(mockAggregator.address);

        vm.stopBroadcast();
    }
}
