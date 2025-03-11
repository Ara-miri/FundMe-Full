// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast(); // Start sending transactions

        // Deploy FundMe contract with the selected price feed
        FundMe fundMe = new FundMe(priceFeed);
        console.log("Deployed FundMe contract at address: %s", address(fundMe));
        vm.stopBroadcast(); // Stop sending transactions
        return fundMe;
    }
}
