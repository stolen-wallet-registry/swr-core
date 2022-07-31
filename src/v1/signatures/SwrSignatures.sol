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

    bytes32 private constant ACKNOWLEDGEMENT_TYPEHASH =
        keccak256("acknowledgementOfRegistry(address owner,address forwarder,uint256 nonce,uint256 deadline)");
    bytes32 private constant REGISTRATION_TYPEHASH =
        keccak256("registerWallet(address owner,address forwarder,uint256 nonce,uint256 deadline)");

    // mapping(address => TrustedForwarder) private acknowledgementForwarders;
    mapping(address => TrustedForwarder) private trustedForwarders;
    mapping(address => uint256) public nonces;

    event AcknowledgementEvent(address indexed owner, bool indexed isSponsored);
    event RegistrationEvent(address indexed owner, bool indexed isSponsored);

    constructor() EIP712Registration("Registration", "4") EIP712Acknowledgement("AcknowledgementOfRegistry", "4") {}

    function acknowledgementOfRegistry(
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        // ensure signature was sent within the time limit
        if (deadline <= block.timestamp) revert AcknowlegementExpired();

        // verify signature was sent by owner
        bytes32 digest = _hashTypedDataV4Acknowledgement(
            keccak256(abi.encode(ACKNOWLEDGEMENT_TYPEHASH, owner, msg.sender, nonces[owner]++, deadline))
        );

        address recoveredWallet = ecrecover(digest, v, r, s);
        if (recoveredWallet == address(0) && recoveredWallet != owner) revert InvalidSigner();

        // sets trusted forwarder and
        trustedForwarders[owner] = TrustedForwarder({
            trustedForwarder: msg.sender,
            startTime: _getStartTime(),
            expirey: _getDeadline()
        });

        if (owner == msg.sender) {
            emit AcknowledgementEvent(owner, false);
        } else {
            emit AcknowledgementEvent(owner, true);
        }
    }

    function generateHashStruct(address forwarder) external view returns (bytes32 hashStruct, uint256 deadline) {
        uint256 deadline = _getDeadline();
        console.log("deadline: ", deadline);
        // bytes32 hashStruct = keccak256("2");

        console.log("deadline", deadline);
        bytes32 hashStruct = keccak256(
            abi.encode(ACKNOWLEDGEMENT_TYPEHASH, msg.sender, forwarder, nonces[msg.sender] + 1, deadline)
        );
    }

    function walletRegistration(
        address owner,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        if (deadline <= block.timestamp) revert SignatureExpired();

        bytes32 digest = _hashTypedDataV4Registration(
            keccak256(abi.encode(REGISTRATION_TYPEHASH, owner, msg.sender, nonces[owner]++, deadline))
        );

        address recoveredWallet = ecrecover(digest, v, r, s);
        if (recoveredWallet == address(0) && recoveredWallet != owner) revert InvalidSigner();

        TrustedForwarder storage forwarder = trustedForwarders[owner];

        if (forwarder.trustedForwarder != msg.sender) revert InvalidForwarder();

        if (forwarder.expirey < block.timestamp) {
            delete trustedForwarders[owner];
            revert ForwarderExpired();
        }

        delete trustedForwarders[owner];

        if (owner == msg.sender) {
            emit RegistrationEvent(owner, false);
        } else {
            emit RegistrationEvent(owner, true);
        }
    }

    function getDeadline() external view returns (uint256) {
        return trustedForwarders[msg.sender].expirey;
    }

    function getTrustedForwarder() public view returns (address) {
        return trustedForwarders[msg.sender].trustedForwarder;
    }

    function getStartTime() external view returns (uint256) {
        return trustedForwarders[msg.sender].startTime;
    }

    function getDeadline(address owner) external view returns (uint256) {
        return trustedForwarders[owner].expirey;
    }

    function getTrustedForwarder(address owner) public view returns (address) {
        return trustedForwarders[owner].trustedForwarder;
    }

    function getStartTime(address owner) external view returns (uint256) {
        return trustedForwarders[owner].startTime;
    }

    function _getDeadline() internal view returns (uint256) {
        return block.timestamp + 4 minutes;
    }

    function _getStartTime() internal view returns (uint256) {
        return block.timestamp + 1 minutes;
    }
}
