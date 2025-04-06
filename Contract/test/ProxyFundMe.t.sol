pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMeV2} from "../src/FundMeV2.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy, ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract ProxyFundMeTest is Test {
    address upgradeAdmin;
    FundMeV2 public fundMeV2;
    FundMe public fundMeV1;
    TransparentUpgradeableProxy public proxy;
    address proxyAdmin;
    HelperConfig public helperConfig;
    address priceFeedAddress;

    address public constant USER = address(1);
    uint256 public constant SEND_VALUE = 1 ether;
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        helperConfig = new HelperConfig();
        priceFeedAddress = helperConfig.activeNetworkConfig();
        fundMeV2 = new FundMeV2();
        proxy = new TransparentUpgradeableProxy(
            address(fundMeV2),
            msg.sender,
            abi.encodeWithSelector(FundMe.initialize.selector, priceFeedAddress) // Initializer data
        );
        fundMeV2 = FundMeV2(payable(address(proxy)));
        upgradeAdmin = msg.sender;

        /**
         * @dev Storage slot with the admin of the contract.
         * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
         * Loading the slot with the address from the actual proxyAdmin in setUp() to prevent from extra complecations.
         */
        bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 data = vm.load(address(proxy), adminSlot);
        proxyAdmin = address(uint160(uint256(data)));

        vm.deal(USER, 10 ether); // We give the fake user a starting balance of ETH
    }

    /**
     * @dev In this test, we upgrade the proxy to a new implementation using the actual proxyAdmin
     * with another account except the upgradeAdmin and expect to revert.
     */
    function testRevert_OnlyOwnerCanUpgrade() public {
        address nonOwner = makeAddr("nonOwner");

        FundMeV2 newImpl = new FundMeV2();
        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                nonOwner
            )
        );
        ProxyAdmin(proxyAdmin).upgradeAndCall(
            ITransparentUpgradeableProxy(address(proxy)),
            address(newImpl),
            ""
        );
    }

    function test_UserFundsPersistAfterV1ToV2Upgrade() public {
        // 1. Set state in V1
        vm.startPrank(USER);
        fundMeV2.fund{value: SEND_VALUE}();
        uint256 initialAmount = fundMeV2.getAddressToAmountFunded(USER);
        vm.stopPrank();
        // 2. Verify state persists in V2
        assertEq(fundMeV2.getAddressToAmountFunded(USER), initialAmount);
    }

    function test_UserWithdrawalFunctionalityAfterV1ToV2Upgrade() public {
        // Used previous test to upgrade to V2 and fund the contract
        test_UserFundsPersistAfterV1ToV2Upgrade();
        uint256 contractBalance = address(fundMeV2).balance;
        uint256 userBalanceInContract = fundMeV2.getAddressToAmountFunded(USER);
        // User funds 1 ether to contract, so contract balance and user balance in contract should be equal to 1 ether
        assertEq(contractBalance, userBalanceInContract);

        vm.startPrank(USER);
        // expect revert if user tries to withdraw before 2 minutes
        vm.expectRevert(abi.encodeWithSignature("FundMe__WithdrawalLocked()"));
        fundMeV2.withdraw();

        skip(2 minutes);

        fundMeV2.withdraw();
        vm.stopPrank();
        assertTrue(
            address(fundMeV2).balance == 0 &&
                fundMeV2.getAddressToAmountFunded(USER) == 0,
            "Balances not reset"
        );
    }

    function test_FundMeV2NewFunction() public {
        uint256 testValue = 42;
        vm.prank(USER);
        // setNewValue is a new function in FundMeV2
        fundMeV2.setNewValue(testValue);

        uint256 value = fundMeV2.getNewValue();
        assertEq(value, testValue);
    }
}
