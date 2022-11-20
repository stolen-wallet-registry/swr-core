// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../StolenWalletRegistry.sol";
import "./MockV3Aggregator.sol";
import "./mocks/HelperConfig.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {BaseTestHarness} from "./utils/BaseTestHarness.sol";

contract StolenWalletRegistryTest is BaseTestHarness {
    using stdStorage for StdStorage;

    uint8 internal decimals;
    int256 internal answer;
    MockV3Aggregator internal mockAggregator;
    StolenWalletRegistry internal stolenWalletRegistry;

    address internal alice;
    address internal bob;
    address internal charlie;

    function setUp() public {
        decimals = 8;
        answer = 169800000000;
        mockAggregator = new MockV3Aggregator(decimals, answer);
        stolenWalletRegistry = new StolenWalletRegistry(address(mockAggregator));

        alice = vm.addr(1);
        bob = vm.addr(2);
        charlie = vm.addr(3);
    }

    // function testSignature() {
    //     vm.deal(alice, 1 ether);
    //     vm.startPrank(payable(alice));
    //     (bytes32 hashStruct, uint256 deadline) = stolenWalletRegistry.generateHashStruct(bob);
    //     bytes32 hash = keccak256("acknowledgementOfRegistry(address owner,address forwarder)");

    //     bytes memory sig = vm.sign(alice, hash, alice, bob);
    //     (bytes32 r, bytes32 s, uint8 v) = splitSignature(hashStruct);

    //     vm.stopPrank();

    //     vm.startPrank(payable(bob));

    //     stolenWalletRegistry.acknowledgementOfRegistry{value: 1 ether}(alice, v, r, s);

    //     vm.stopPrank();
    //     // uint8 v,
    //     // bytes32 r,
    //     // bytes32 s
    // }

    function testMyWalletWasStolen(
        uint256 userFunds,
        uint256 ethPrice,
        uint8 registrationTimestamp
    ) public {
        assertEq(stolenWalletRegistry.registeredWalletCount(), 0);

        ethPrice = bound(ethPrice, 100000000000, 300000000000); // bound eth price between $1000 and $3000

        uint256 requiredAmount = getRequiredAmount(stolenWalletRegistry.publicGoodsRegistrationFee(), ethPrice);
        userFunds = bound(userFunds, requiredAmount / 2, requiredAmount * 2);

        vm.deal(alice, userFunds);
        vm.startPrank(payable(alice));

        vm.mockCall(
            address(mockAggregator),
            abi.encodeWithSelector(mockAggregator.getLatestPrice.selector),
            abi.encode(ethPrice) // $1698.00000000 / ETH
        );

        vm.warp(registrationTimestamp);

        if (userFunds > requiredAmount) {
            stolenWalletRegistry.myWalletWasStolen{value: userFunds}();
            assertEq(stolenWalletRegistry.registeredWalletCount(), 1);
            assertEq(stolenWalletRegistry.registeredWallets(alice), uint256(registrationTimestamp));
        } else {
            vm.expectRevert(StolenWalletRegistry.NotEnoughFunds.selector);
            stolenWalletRegistry.myWalletWasStolen{value: userFunds}();
            assertEq(stolenWalletRegistry.registeredWalletCount(), 0);
        }

        vm.clearMockedCalls();
        vm.stopPrank();
    }

    function testIsWalletRegistered(uint8 registrationTimestamp) public {
        vm.assume(registrationTimestamp > 0);
        vm.warp(registrationTimestamp);
        assertEq(stolenWalletRegistry.isWalletRegistered(alice), false);

        stdstore.target(address(stolenWalletRegistry)).sig("registeredWallets(address)").with_key(alice).checked_write(
            block.timestamp
        );

        skip(1);
        assertEq(stolenWalletRegistry.isWalletRegistered(alice), true);
        assertEq(stolenWalletRegistry.isWalletRegistered(bob), false);

        vm.prank(alice);
        assertEq(stolenWalletRegistry.isWalletRegistered(), true);
        vm.prank(charlie);
        assertEq(stolenWalletRegistry.isWalletRegistered(), false);
    }

    function testwhenWalletWasRegistered(uint8 registrationTimestamp, uint8 forwardTimestamp) public {
        vm.assume(registrationTimestamp > 0);
        vm.assume(forwardTimestamp > registrationTimestamp);

        vm.warp(registrationTimestamp);
        assertEq(stolenWalletRegistry.whenWalletWasRegisted(alice), 0);

        stdstore.target(address(stolenWalletRegistry)).sig("registeredWallets(address)").with_key(alice).checked_write(
            registrationTimestamp
        );

        skip(forwardTimestamp);
        assertEq(stolenWalletRegistry.whenWalletWasRegisted(alice), registrationTimestamp);
        assertEq(stolenWalletRegistry.whenWalletWasRegisted(bob), 0);

        vm.prank(alice);
        assertEq(stolenWalletRegistry.whenWalletWasRegisted(), registrationTimestamp);
        vm.prank(charlie);
        assertEq(stolenWalletRegistry.whenWalletWasRegisted(), 0);
    }

    // function testAcknowledgementOfRegistry() public {}

    // function testGenerateHashStruct() public {}

    // function testWalletRegistration() public {}

    // function testGetDeadline(uint8 registrationTimestamp) public {
    //     // struct TrustedForwarder {
    //     //     address trustedForwarder;
    //     //     uint256 startTime;
    //     //     uint256 expirey;
    //     // }
    //     uint256 expirey = uint256(registrationTimestamp + stolenWalletRegistry.DEADLINE_MINUTES());
    //     stdstore
    //         .target(address(stolenWalletRegistry))
    //         .sig("trustedForwarders(address)")
    //         .with_key(alice)
    //         .depth(2)
    //         .checked_write(expirey);
    //     uint256 slot = stdstore
    //         .target(address(stolenWalletRegistry))
    //         .sig(stolenWalletRegistry.trustedForwarders.selector)
    //         .with_key(alice)
    //         .find();
    //     uint256 data = vm.load(address(stolenWalletRegistry), bytes32(slot));
    //     assertEq(stolenWalletRegistry.getDeadline(alice), data);
    //     vm.prank(alice);
    //     assertEq(stolenWalletRegistry.getDeadline(), data);
    //     vm.prank(charlie);
    //     assertEq(stolenWalletRegistry.getDeadline(), 0);
    // }

    function testGetTrustedForwarder() public {}

    function testGetStartTime() public {}

    function testGetDeadline(address owner) public {}

    function testGetTrustedForwarder(address owner) public {}

    function testGetStartTime(address owner) public {}
}
