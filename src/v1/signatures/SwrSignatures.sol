// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./EIP712Registration.sol";
import "./EIP712Acknowledgement.sol";
import "forge-std/console.sol";

/// @author FooBar
/// @title A simple FooBar example
abstract contract SwrSignatures is EIP712Registration, EIP712Acknowledgement {
    error AcknowlegementExpired();
    error InvalidSigner();
    error InvalidForwarder();
    error SignatureExpired();
    error ForwarderExpired();

    struct TrustedForwarder {
        address trustedForwarder;
        uint256 startTime;
        uint256 expirey;
    }

    uint8 public constant START_TIME_MINUTES = 1 minutes;
    uint16 public constant DEADLINE_MINUTES = 6 minutes;

    // ethereum blocks at avg 15 seconds to settle
    uint256 public constant START_TIME_BLOCKS = 4; // 4 blocks equals 1 minute of time on avg.
    uint256 public constant DEADLINE_BLOCKS = 55; // 55 * 15 = 825 seconds, roughtly 13 minutes to complete registration.

    bytes32 private constant ACKNOWLEDGEMENT_TYPEHASH =
        keccak256("AcknowledgementOfRegistry(address owner,address forwarder,uint256 nonce,uint256 deadline)");
    bytes32 private constant REGISTRATION_TYPEHASH =
        keccak256("Registration(address owner,address forwarder,uint256 nonce,uint256 deadline)");

    mapping(address => TrustedForwarder) private acknowledgementForwarders;
    mapping(address => TrustedForwarder) private trustedForwarders;
    mapping(address => uint256) public nonces;

    event AcknowledgementEvent(address indexed owner, bool indexed isSponsored);
    event RegistrationEvent(address indexed owner, bool indexed isSponsored);

    constructor() EIP712Registration("Registration", "4") EIP712Acknowledgement("AcknowledgementOfRegistry", "4") {}

    function acknowledgementOfRegistry(
        uint256 deadline,
        uint256 nonce,
        address owner,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        // ensure signature was sent within the time limit
        if (deadline <= block.timestamp) revert AcknowlegementExpired();

        // verify signature was sent by owner
        // TODO tx.origin can fit somewhere in here for further assurances?
        bytes32 digest = _hashTypedDataV4Acknowledgement(
            keccak256(abi.encode(ACKNOWLEDGEMENT_TYPEHASH, owner, msg.sender, nonces[owner], deadline))
        );

        address recoveredWallet = ECDSA.recover(digest, v, r, s);
        if (recoveredWallet == address(0)) revert InvalidSigner();
        if (recoveredWallet != owner) revert InvalidSigner();

        nonces[owner]++;
        // sets trusted forwarder and
        trustedForwarders[owner] = TrustedForwarder({
            trustedForwarder: msg.sender,
            startTime: _getStartTimeBlock(),
            expirey: _getDeadlineBlock()
        });

        if (owner == msg.sender) {
            emit AcknowledgementEvent(owner, false);
        } else {
            emit AcknowledgementEvent(owner, true);
        }
    }

    function generateHashStruct(address forwarder) public view returns (uint256 deadline, bytes32 hashStruct) {
        uint256 deadline = _getDeadline();
        bytes32 hashStruct = keccak256(
            abi.encode(ACKNOWLEDGEMENT_TYPEHASH, msg.sender, forwarder, nonces[msg.sender], deadline)
        );

        return (deadline, hashStruct);
    }

    function walletRegistration(
        uint256 deadline,
        uint256 nonce,
        address owner,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable returns (address) {
        if (deadline <= block.timestamp) revert SignatureExpired();

        bytes32 digest = _hashTypedDataV4Registration(
            keccak256(abi.encode(REGISTRATION_TYPEHASH, owner, msg.sender, nonces[owner], deadline))
        );

        address recoveredWallet = ECDSA.recover(digest, v, r, s);
        if (recoveredWallet == address(0)) revert InvalidSigner();
        if (recoveredWallet != owner) revert InvalidSigner();

        TrustedForwarder storage forwarder = trustedForwarders[owner];

        if (forwarder.trustedForwarder != msg.sender) revert InvalidForwarder();

        if (forwarder.expirey <= block.number) {
            delete trustedForwarders[owner];
            revert ForwarderExpired();
        }

        delete trustedForwarders[owner];

        if (owner == msg.sender) {
            emit RegistrationEvent(owner, false);
        } else {
            emit RegistrationEvent(owner, true);
        }

        return address(owner);
    }

    function getTrustedForwarder() public view returns (address) {
        return trustedForwarders[msg.sender].trustedForwarder;
    }

    function getDeadline() public view returns (uint256) {
        return trustedForwarders[msg.sender].expirey;
    }

    // _gracePeriodSecsLeft
    // _registrationPeriodSecsLeft
    // _expired
    function getDeadlines(address session)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        TrustedForwarder storage forwarder = trustedForwarders[session];

        require(forwarder.trustedForwarder == msg.sender || session == msg.sender, "Invalid query");

        if (forwarder.expirey < block.number) {
            // expired
            return (block.number, forwarder.expirey, forwarder.startTime, 0, 0, true);
        }

        if (forwarder.startTime < block.number) {
            // in registration period
            return (block.number, forwarder.expirey, forwarder.startTime, 0, forwarder.expirey - block.number, false);
        }

        // in grace period
        return (
            block.number,
            forwarder.expirey,
            forwarder.startTime,
            forwarder.startTime - block.number,
            forwarder.expirey - block.number,
            false
        );
    }

    function gracePeriodLeft() public view returns (uint256 _secondsLeft) {
        TrustedForwarder storage forwarder = trustedForwarders[msg.sender];

        require(block.timestamp <= forwarder.startTime);
        uint256 _secondsLeft = forwarder.startTime - block.timestamp;
    }

    function registrationPeriodLeft() public view returns (uint256 _secondsLeft) {
        TrustedForwarder storage forwarder = trustedForwarders[msg.sender];

        require(block.timestamp <= forwarder.expirey);
        uint256 _secondsLeft = forwarder.startTime - block.timestamp;
    }

    function regististrationPeriodExpired() public view returns (bool) {
        return block.timestamp > trustedForwarders[msg.sender].expirey;
    }

    function getStartTime() public view returns (uint256) {
        return trustedForwarders[msg.sender].startTime;
    }

    function getDeadline(address owner) public view returns (uint256) {
        return trustedForwarders[owner].expirey;
    }

    function getStartTime(address owner) public view returns (uint256) {
        return trustedForwarders[owner].startTime;
    }

    function _getDeadline() internal view returns (uint256) {
        return block.timestamp + DEADLINE_MINUTES;
    }

    function _getStartTime() internal view returns (uint256) {
        return block.timestamp + START_TIME_MINUTES;
    }

    function _getDeadlineBlock() internal view returns (uint256) {
        return block.number + DEADLINE_BLOCKS;
    }

    function _getStartTimeBlock() internal view returns (uint256) {
        return block.number + START_TIME_BLOCKS;
    }
}
