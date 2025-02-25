// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {FundToMe} from "../src/FundToMe.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundToMe is Script {
  function run() external returns (FundToMe) {
    HelperConfig helperConfig = new HelperConfig();
    address priceFeed = helperConfig.activeNetworkConfig();

    vm.startBroadcast(); // Start sending transactions

    // 🔹 Deploy FundMe contract with the selected price feed
    FundToMe fundMe = new FundToMe(priceFeed);
    vm.stopBroadcast(); // Stop sending transactions
    return fundMe;
  }
}
