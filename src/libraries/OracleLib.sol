// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author 0xavci
 * @notice This library is used to check the Chainlink oracle for stability.
 * If the price is stale, the function will revert, and render the DSCEngine unusable - This is a design choice.
 *
 * We want DSCEngine to freeze if price become stale.
 *
 * If Chainlink network becames out of service, this makes our protocol locked with user's money.
 * We don't want that, do we?
 *
 */
library OracleLib {

    error OracleLib__StalePriceFeed();


        uint256 private constant TIMEOUT = 3 hours; // 3 * 60 * 60 = 10800 seconds



    function priceStaleCheckLatestRoundData(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            priceFeed.latestRoundData();

        uint256 secondsSince = block.timestamp - updatedAt;

        if (secondsSince > TIMEOUT) revert OracleLib__StalePriceFeed();

        return (roundId, answer, startedAt, updatedAt, answeredInRound);

    }
}
