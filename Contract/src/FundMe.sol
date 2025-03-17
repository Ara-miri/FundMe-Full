// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./Helpers/PriceConverter.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract FundMe {
    // Errors
    error FundMe__InsufficientFunds();
    error FundMe__TransferFailed();
    error FundMe__NoFundsAvailable();
    error FundMe__WithdrawalLocked();
    error FundMe__NoContributionsFound();

    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant WITHDRAWAL_LOCK_DURATION = 2 minutes;
    // s_funderContributionsByTimestamp tracks contributions block.timestamp for each funder to check withdrawal lock duration with it on withdrawal
    mapping(address => uint256[]) private s_funderContributionsByTimestamp;
    // s_addressToAmountFunded stores sum of all the fundings of an address
    mapping(address => uint256) private s_addressToAmountFunded;
    uint256 public constant MINIMUM_USD = 1 * 10 ** 6;
    // s_fundingsByUser stores the value of each fundings an address had
    mapping(address => uint256[]) private s_fundingsByUser;
    AggregatorV3Interface private s_priceFeed;

    // Events
    event Fund(address indexed funder, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);
    event ContributionsByFunder(
        address indexed funder,
        uint256[] contributions
    );

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__InsufficientFunds();
        }

        s_funderContributionsByTimestamp[msg.sender].push(block.timestamp); // Record the contribution timestamp
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_fundingsByUser[msg.sender].push(msg.value);

        emit ContributionsByFunder(
            msg.sender,
            s_funderContributionsByTimestamp[msg.sender]
        );
        emit Fund(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = s_addressToAmountFunded[msg.sender];
        if (!amount > 0) {
            revert FundMe__NoFundsAvailable();
        }

        uint256 timeRemaining = getTimeRemainingForWithdrawal(msg.sender);
        if (timeRemaining != 0) {
            revert FundMe__WithdrawalLocked();
        }

        // Reset the caller's fundings
        s_addressToAmountFunded[msg.sender] = 0;
        // Reset the caller's fundings list to empty
        s_fundingsByUser;
        delete s_funderContributionsByTimestamp[msg.sender];

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FundMe__TransferFailed();
        emit Withdraw(msg.sender, amount);
    }

    function getTimeRemainingForWithdrawal(
        address _funder
    ) public view returns (uint256) {
        uint256[] memory contributions = s_funderContributionsByTimestamp[
            _funder
        ];
        if (!contributions.length > 0) {
            revert FundMe__NoContributionsFound();
        }

        uint256 lastContribution = contributions[contributions.length - 1]; // Get the most recent contribution

        uint256 unlockTime = lastContribution + WITHDRAWAL_LOCK_DURATION;

        if (block.timestamp < unlockTime) {
            return unlockTime - block.timestamp;
        } else {
            return 0;
        }
    }

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunderContributionsTimestamps(
        address _funder
    ) public view returns (uint256[] memory) {
        return s_funderContributionsByTimestamp[_funder];
    }

    function getFundingsByUser(
        address _funder
    ) public view returns (uint256[] memory) {
        return s_fundingsByUser[_funder];
    }

    function getFunderContributionsLength(
        address _funder
    ) public view returns (uint256) {
        return s_funderContributionsByTimestamp[_funder].length;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
