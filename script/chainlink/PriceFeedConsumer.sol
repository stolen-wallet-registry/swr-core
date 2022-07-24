// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@std/Script.sol";
import "../../src/v1/helpers/PriceConsumerV3.sol";
import "./HelperConfig.sol";
import "./MockV3Aggregator.sol";

contract DeployPriceFeedConsumer is Script, HelperConfig {
    uint8 constant DECIMALS = 18;
    int256 constant INITIAL_ANSWER = 2000e18;

    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        (, , , , , address priceFeed, , , ) = helperConfig.activeNetworkConfig();

        if (priceFeed == address(0)) {
            priceFeed = address(new MockV3Aggregator(DECIMALS, INITIAL_ANSWER));
        }

        vm.startBroadcast();

        PriceFeedConsumer priceFeedConsumer = new PriceFeedConsumer(priceFeed);

        vm.stopBroadcast();
    }
}
