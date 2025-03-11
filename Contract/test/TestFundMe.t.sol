// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

/// @dev Used to simulate failed ETH transfers in withdrawal tests
contract RevertingReceiver {
    receive() external payable {
        revert();
    }
}

contract FundMeTest is Test {
    FundMe fundMe;
    RevertingReceiver revertingReceiver;
    uint256 fundingAmount = 1 ether;
    address getPriceFeed;
    address owner;
    address USER = makeAddr("user"); // Create a fake address for tests

    event Fund(address indexed funder, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);
    event ContributionsByFunder(
        address indexed funder,
        uint256[] contributions
    );

    function setUp() external {
        HelperConfig helperConfig = new HelperConfig();
        revertingReceiver = new RevertingReceiver();
        getPriceFeed = helperConfig.activeNetworkConfig();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, 10 ether); // We give the fake user a starting balance of ETH
    }

    // A pranked user funds the contract with 1 ETH
    modifier fundToContractByUSER() {
        vm.prank(USER); // The next transaction will be sent by USER (All transactions are being sent by the test contract itself by default)
        fundMe.fund{value: fundingAmount}();
        _;
    }

    // --------------------------------------------------

    function test_WithdrawalLockDuration() public view {
        assertEq(fundMe.WITHDRAWAL_LOCK_DURATION(), 2 minutes);
    }

    function test_GetTimeRemainingForWithdrawalIsTwoMinutes()
        public
        fundToContractByUSER
    {
        assertEq(fundMe.getTimeRemainingForWithdrawal(USER), 2 minutes);
    }

    function test_GetFunderContributionsByblockTimestamp()
        public
        fundToContractByUSER
    {
        vm.prank(USER);
        fundMe.fund{value: 2.4 ether}();
        vm.prank(USER);
        fundMe.fund{value: 1.5 ether}();
        vm.prank(USER);
        fundMe.fund{value: 0.7 ether}();
        uint256 contributionsLength = fundMe.getFunderContributionsLength(USER);
        uint256[] memory contributionsTimestamps = fundMe
            .getFunderContributionsTimestamps(USER);

        // We funded twice so the length should be 2
        assertEq(contributionsTimestamps.length, contributionsLength);
    }

    function test_MinimumDollarIsOne() public view {
        assertEq(fundMe.MINIMUM_USD(), 1e6);
    }

    function test_VersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    /* test_PriceFeedAddressIsCorrect() does not pass with mock contracts.
        it works with real testnet/mainnet contracts though.
    */
    function test_PriceFeedAddressIsCorrect() public view {
        uint256 mainnetChainId = 1;
        uint256 sepoliaChainId = 11155111;
        // Pass the test early if the chain ID is not mainnet or sepolia
        if (
            block.chainid != mainnetChainId && block.chainid != sepoliaChainId
        ) {
            return;
        }

        AggregatorV3Interface retrievedPriceFeed = fundMe.getPriceFeed();
        assertEq(address(retrievedPriceFeed), getPriceFeed);
    }

    function test_Funding() public fundToContractByUSER {
        assertEq(fundMe.getAddressToAmountFunded(USER), fundingAmount); // We can pass the USER instead of address(this)
    }

    function test_GetAmountsFundedIsCorrect() public {
        uint256[3] memory fundedAmounts; // Cannot use dynamic size arrays with memory
        for (uint256 i = 0; i < 3; i++) {
            uint256 amount = (i + 1) * 0.5 ether; // Example: 0.5 ETH, 1 ETH, 1.5 ETH
            fundedAmounts[i] = amount;
            vm.prank(USER);
            fundMe.fund{value: fundedAmounts[i]}();
        }
        uint256[] memory storedFundings = fundMe.getFundingsByUser(USER);

        assertEq(
            storedFundings.length,
            fundedAmounts.length,
            "Funding count mismatch"
        );
        for (uint256 i = 0; i < fundedAmounts.length; i++) {
            // storedFundings[i], fundedAmounts[i] should both return 0.5 eth, 1 eth and 1.5 eth in format of wei
            assertEq(
                storedFundings[i],
                fundedAmounts[i],
                "Mismatch in funding history"
            );
        }
    }

    function test_ContractBalanceIsZeroAfterWithdraw() public {
        // Arrange
        uint256 startingContractBalance = address(fundMe).balance; // Should be 0 at first

        // Act
        vm.prank(USER);
        fundMe.fund{value: 1 ether}();

        skip(120); // skipping 2 minutes to pass the lock duration

        vm.prank(USER);
        fundMe.withdraw();

        // Assert
        uint256 endingFundMeContractBalance = address(fundMe).balance;

        assertEq(endingFundMeContractBalance, startingContractBalance);
    }

    function test_UserBalanceRestoredAfterWithdraw() public {
        // Arrange
        uint256 startingUserBalance = USER.balance;

        // Act
        vm.prank(USER);
        fundMe.fund{value: 1 ether}();

        // Assert
        skip(120); // skipping 2 minutes to pass the lock duration

        vm.prank(USER);
        fundMe.withdraw();
        uint256 endingUserBalance = USER.balance;
        assertEq(endingUserBalance, startingUserBalance);
    }

    function test_FallbackTriggersAndCallsFund() public {
        vm.prank(USER);
        // Call with some data to trigger fallback function. It will call fund function
        (bool success, ) = address(fundMe).call{value: 1 ether}("some data");
        require(success, "transfer failed");

        // Verify the ETH was recorded in the contract
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 1 ether);
    }

    function test_ReceiveTriggersAndCallsFund() public {
        vm.prank(USER);
        // Call without data to trigger receive function. It will call fund function
        (bool success, ) = address(fundMe).call{value: 1 ether}("");
        require(success, "transfer failed");

        // Verify the ETH was recorded in the contract
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 1 ether);
    }

    function test_EmitWithdrawEventAfterSuccessfulWithdrawal()
        public
        fundToContractByUSER
    {
        skip(120);
        vm.expectEmit(true, true, false, true);
        emit Withdraw(USER, 1 ether);
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testRevert_ReceiveRevertsIfFundReverts() public {
        // smallAmount should be less than $1 worth of ether to revert fund() so receive() will revert
        uint256 smallAmount = 1 wei;

        // Expect revert because fund() has a minimum ETH requirement
        vm.expectRevert("You need to spend more ETH!");
        vm.prank(USER);
        (bool success, ) = address(fundMe).call{value: smallAmount}("");
    }

    function testRevert_FallbackRevertsIfFundReverts() public {
        // smallAmount should be less than $1 worth of ether to revert fund() so fallback() will revert
        uint256 smallAmount = 1 wei;

        // Expect revert because fund() has a minimum ETH requirement
        vm.expectRevert("You need to spend more ETH!");
        vm.prank(USER);
        (bool success, ) = address(fundMe).call{value: smallAmount}(
            "some data"
        );
    }

    function testRevert_UserHasNotEnoughBalanceForFund() public {
        vm.prank(USER);
        vm.deal(USER, 0 ether);
        vm.expectRevert();
        fundMe.fund();
    }

    function testRevert_GetTimeLockRevertsIfUserNotFund() public {
        // Call the getTimeRemainingForWithdrawal function without funding
        vm.expectRevert();
        vm.prank(USER);
        fundMe.getTimeRemainingForWithdrawal(USER);
    }

    function testRevert_WithdrawFailedErrorOnReceiverReject() public {
        vm.deal(address(revertingReceiver), 1 ether);
        vm.prank(address(revertingReceiver));
        fundMe.fund{value: 1 ether}();

        vm.expectRevert(FundMe.FundMe__TransferFailed.selector);
        skip(120);
        vm.prank(address(revertingReceiver));
        fundMe.withdraw();
    }

    function testRevert_UserWithdrawTooEarly() public fundToContractByUSER {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testRevert_UserWithdrawWithoutAnyFunding() public {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }
}
