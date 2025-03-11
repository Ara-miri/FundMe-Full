// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;
    int public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 11155420) {
            activeNetworkConfig = getOptimismConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getOptimismConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory opConfig = NetworkConfig({
            priceFeed: 0x61Ec26aA57019C486B10502285c5A3D4A4750AD7
        });
        return opConfig;
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // check to return the config if we deployed the mock before
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        // deploy the mock aggregator and return the price feed address
        vm.startBroadcast();
        MockV3Aggregator mock = new MockV3Aggregator(INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mock)
        });
        return anvilConfig;
    }
}
