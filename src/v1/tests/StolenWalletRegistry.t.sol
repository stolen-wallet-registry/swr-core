// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../StolenWalletRegistry.sol";
import "./MockV3Aggregator.sol";
import "./mocks/HelperConfig.sol";

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console2.sol";

contract StolenWalletRegistryTest is Test {
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

    function testMyWalletWasStolen(
        uint256 aliceMsgValue,
        uint256 ethPrice,
        uint8 registrationTimestamp
    ) public {
        assertEq(stolenWalletRegistry.registeredWalletCount(), 0);

        ethPrice = bound(ethPrice, 100000000000, 300000000000); // bound eth price between $1000 and $3000

        uint256 enumerator = stolenWalletRegistry.publicGoodsRegistrationFee() * 10**18;
        uint256 denominator = uint256(ethPrice / 10**8);
        uint256 requiredAmount = enumerator / denominator;

        aliceMsgValue = bound(aliceMsgValue, requiredAmount, requiredAmount * 2);
        vm.deal(alice, aliceMsgValue);

        vm.startPrank(payable(alice));

        vm.mockCall(
            address(mockAggregator),
            abi.encodeWithSelector(mockAggregator.getLatestPrice.selector),
            abi.encode(ethPrice) // $1698.00000000 / ETH
        );

        vm.warp(registrationTimestamp);

        if (aliceMsgValue > requiredAmount) {
            stolenWalletRegistry.myWalletWasStolen{value: aliceMsgValue}();
            assertEq(stolenWalletRegistry.registeredWalletCount(), 1);
            assertEq(stolenWalletRegistry.registeredWallets(alice), uint256(registrationTimestamp));
        } else {
            vm.expectRevert(StolenWalletRegistry.NotEnoughFunds.selector);
            stolenWalletRegistry.myWalletWasStolen{value: aliceMsgValue}();
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
