// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@helpers/PriceConsumerV3.sol";
import "@helpers/PublicGoodsAreGood.sol";
import "./signatures/SwrSignatures.sol";

interface IStolenWalletRegistry {
    function myWalletWasStolen() external returns (bool);

    function _myWalletWasStolen(address wallet) external returns (bool);
}

/// @title A registry for reporting stolen wallets
/// @author brianrossetti.eth
/// @notice This contract is used as a Registry for signaling that a wallet address has been compromised.
/// @notice funds from fees routed from other chains go to the address registered at protocolguild.eth
/// @notice funds from fees on Optimism go to the Optimism retroactive public goods fund.
/// @custom:experimental This is an experimental unaudited contract.
contract StolenWalletRegistry is SwrSignatures {
    PriceFeedConsumer public priceConsumer;

    // $5 USD per registration
    uint256 public publicGoodsRegistrationFee = 5;
    uint256 public registeredWalletCount = 0;

    mapping(address => uint256) public registeredWallets;

    error NotEnoughFunds();
    error UserAlreadyRegistered(address wallet);

    event RegisteredAddressEvent(address registeredWallet, bool gasless);
    event MsgValue(uint256 value1, uint256 value2, uint256 cost);

    constructor(address _priceFeed) SwrSignatures() {
        priceConsumer = PriceFeedConsumer(_priceFeed);
    }

    modifier checkFundsForPublicGoods() {
        uint256 cost = ((publicGoodsRegistrationFee * 10**18) / getLatestETHUSDPrice());
        emit MsgValue(getLatestETHUSDPrice(), publicGoodsRegistrationFee * 10**18, cost);
        if (msg.value <= cost) revert NotEnoughFunds();
        if (_isWalletRegistered()) revert UserAlreadyRegistered(msg.sender);

        _;
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    function myWalletWasStolen() external payable checkFundsForPublicGoods {
        registeredWallets[msg.sender] = block.timestamp;
        registeredWalletCount++;

        emit RegisteredAddressEvent(msg.sender, false);

        // fundOptimismRetroactivePublicGoods();
    }

    function isWalletRegistered(address wallet) public view returns (bool) {
        return registeredWallets[wallet] != 0 && registeredWallets[wallet] < block.timestamp;
    }

    function isWalletRegistered() public view returns (bool) {
        return _isWalletRegistered();
    }

    function whenWalletWasRegisted(address wallet) public view returns (uint256) {
        return registeredWallets[wallet];
    }

    function whenWalletWasRegisted() public view returns (uint256) {
        return registeredWallets[msg.sender];
    }

    function fundProtocolGuild() internal {
        (bool sent, ) = PublicGoodsAreGood.resolveProtcolGuildAddress().call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function fundOptimismRetroactivePublicGoods() internal {
        (bool sent, ) = PublicGoodsAreGood.resolveOptimismRetroactiveAddress().call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function _isWalletRegistered() private view returns (bool) {
        return registeredWallets[msg.sender] != 0 && registeredWallets[msg.sender] < block.timestamp;
    }

    /// @notice chainlink ETH/USD returns 8 decimals
    /// division by 10 ** 8 converts the price to a divisor for $x USD of ETH
    /// divisor is used above to calculate publicGoodsRegistrationFee as $x USD in ETH
    /// @dev Explain to a developer any extra details
    function getLatestETHUSDPrice() internal view returns (uint256) {
        return uint256(priceConsumer.getLatestPrice()) / 10**8;
    }
}
