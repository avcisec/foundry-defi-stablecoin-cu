// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";


contract HelperConfig is Script {

    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {}

    // function getSepoliaEthConfig() public view returns(NetworkConfig memory )
    // return NetworkConfig({

    // })
}