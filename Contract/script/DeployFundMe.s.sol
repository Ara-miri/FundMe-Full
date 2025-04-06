// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {FundMeV2} from "../src/FundMeV2.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy, ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployFundMe is Script {
    HelperConfig public helperConfig;
    address priceFeedAddress;
    TransparentUpgradeableProxy public proxy;

    function run() external {
        helperConfig = new HelperConfig();
        priceFeedAddress = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FundMeV2 fundMeV2 = new FundMeV2();
        proxy = new TransparentUpgradeableProxy(
            address(fundMeV2),
            msg.sender,
            abi.encodeWithSelector(FundMe.initialize.selector, priceFeedAddress) // Initializer data
        );

        bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 data = vm.load(address(proxy), adminSlot);
        address proxyAdmin = address(uint160(uint256(data)));

        require(ProxyAdmin(proxyAdmin).owner() == msg.sender, "Admin mismatch");

        ProxyAdmin(proxyAdmin).upgradeAndCall(
            ITransparentUpgradeableProxy(address(proxy)),
            address(fundMeV2),
            ""
        );
        fundMeV2 = FundMeV2(payable(address(proxy)));
        vm.stopBroadcast();
    }
}
