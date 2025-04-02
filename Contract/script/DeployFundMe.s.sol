// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployFundMe is Script {
    HelperConfig public helperConfig;
    address priceFeedAddress;
    TransparentUpgradeableProxy public proxy;

    function run()
        external
        returns (FundMe, TransparentUpgradeableProxy, address)
    {
        helperConfig = new HelperConfig();
        priceFeedAddress = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FundMe fundMeV1 = new FundMe();
        proxy = new TransparentUpgradeableProxy(
            address(fundMeV1),
            msg.sender,
            abi.encodeWithSelector(FundMe.initialize.selector, priceFeedAddress) // Initializer data
        );
        fundMeV1 = FundMe(payable(address(proxy)));
        vm.stopBroadcast();

        // return all the values to avoid possible errors in tests
        return (fundMeV1, proxy, msg.sender);
    }
}
