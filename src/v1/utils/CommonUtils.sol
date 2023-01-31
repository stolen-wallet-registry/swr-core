// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @author FooBar
/// @title A simple FooBar example
library CommonUtils {
    uint8 public constant START_TIME_MINUTES = 1 minutes;
    uint16 public constant DEADLINE_MINUTES = 6 minutes;

    // ethereum blocks at avg 15 seconds to settle
    uint256 public constant START_TIME_BLOCKS = 4; // 4 blocks equals 1 minute of time on avg.
    uint256 public constant DEADLINE_BLOCKS = 55; // 55 * 15 = 825 seconds, roughtly 13 mins to register.

    /**
     * @dev Returns the current block number.
     */

    function _getStartTime() internal view returns (uint256) {
        return block.timestamp + _getRandomTime(START_TIME_MINUTES);
    }

    function _getStartTimeBlock() internal view returns (uint256) {
        return block.number + _getRandomBlock(START_TIME_BLOCKS);
    }

    function _getDeadline() internal view returns (uint256) {
        return block.timestamp + _getRandomTime(DEADLINE_MINUTES);
    }

    function _getDeadlineBlock() internal view returns (uint256) {
        return block.number + _getRandomBlock(DEADLINE_BLOCKS);
    }

    function _getRandomTime(uint256 minTime) private view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 60) + minTime;
    }

    function _getRandomBlock(uint256 minBlocks) private view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % minBlocks);
    }
}
