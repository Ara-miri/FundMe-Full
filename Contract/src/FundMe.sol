// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./Helpers/PriceConverter.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

/// @title FundMe
/// @notice A crowdfunding contract that accepts ETH contributions above a minimum USD value.
/// @dev Uses a Chainlink price feed to convert ETH amounts to USD for minimum enforcement.
///      Withdrawals are time-locked — a funder must wait WITHDRAWAL_LOCK_DURATION after
///      their most recent contribution before they can withdraw.
contract FundMe {
    /******************************************************************************
     *                                   Errors                                   *
     ******************************************************************************/

    /// @notice Thrown when a fund() call does not meet the MINIMUM_USD threshold.
    error FundMe__InsufficientFunds();
    /// @notice Thrown when the ETH transfer to the caller fails during withdrawal.
    error FundMe__TransferFailed();
    /// @notice Thrown when withdraw() is called but the caller has no funded balance.
    error FundMe__NoFundsAvailable();
    /// @notice Thrown when withdraw() is called before the withdrawal lock has expired.
    error FundMe__WithdrawalLocked();
    /// @notice Thrown when getTimeRemainingForWithdrawal() is called for an address
    ///         that has never made a contribution.
    error FundMe__NoContributionsFound();

    /******************************************************************************
     *                             Type Declarations                              *
     ******************************************************************************/

    /// @dev Attaches getConversionRate() from PriceConverter to all uint256 values.
    using PriceConverter for uint256;

    /******************************************************************************
     *                              State variables                               *
     ******************************************************************************/

    /// @notice The duration a funder must wait after their last contribution before withdrawing.
    uint256 public constant WITHDRAWAL_LOCK_DURATION = 2 minutes;

    /// @notice Tracks the block.timestamp of each contribution per funder.
    /// @dev Used to enforce the withdrawal lock — the most recent timestamp determines unlock time.
    mapping(address => uint256[]) private s_funderContributionsByTimestamp;

    /// @notice Stores the total cumulative ETH funded by each address.
    mapping(address => uint256) private s_addressToAmountFunded;

    /// @notice The minimum contribution value in USD (with 6 decimal precision, i.e. $1.00).
    uint256 public constant MINIMUM_USD = 1 * 10 ** 6;

    /// @notice Stores each individual funding amount per address in order.
    mapping(address => uint256[]) private s_fundingsByUser;

    /// @notice The Chainlink price feed used to convert ETH to USD.
    AggregatorV3Interface private s_priceFeed;

    /******************************************************************************
     *                                   Events                                   *
     ******************************************************************************/

    /// @notice Emitted when a successful contribution is made.
    /// @param funder The address that funded.
    /// @param amount The ETH amount contributed in wei.
    event Fund(address indexed funder, uint256 amount);

    /// @notice Emitted when a funder successfully withdraws their balance.
    /// @param recipient The address that withdrew.
    /// @param amount The ETH amount withdrawn in wei.
    event Withdraw(address indexed recipient, uint256 amount);

    /// @notice Emitted on every contribution with the funder's full timestamp history.
    /// @param funder The address that funded.
    /// @param contributions All contribution timestamps for this funder up to and including now.
    event ContributionsByFunder(
        address indexed funder,
        uint256[] contributions
    );

    /******************************************************************************
     *                      constructor and Functions                             *
     ******************************************************************************/

    /// @param priceFeed The address of the Chainlink ETH/USD AggregatorV3Interface price feed.
    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /// @notice Routes plain ETH transfers to fund().
    receive() external payable {
        fund();
    }

    /// @notice Routes calls with unknown calldata to fund().
    fallback() external payable {
        fund();
    }

    /******************************************************************************
     *                        External / Public Functions                         *
     ******************************************************************************/

    /// @notice Accepts an ETH contribution if it meets the minimum USD value.
    /// @dev Converts msg.value to USD using the Chainlink price feed via PriceConverter.
    ///      Records the contribution timestamp for withdrawal lock enforcement.
    ///      Reverts if the USD value of msg.value is below MINIMUM_USD.
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

    /// @notice Withdraws the caller's full funded balance if the lock period has passed.
    /// @dev Checks withdrawal lock via getTimeRemainingForWithdrawal before proceeding.
    ///      Resets the caller's total balance and contribution timestamps on success.
    ///      Uses call() for the ETH transfer and reverts on failure.
    function withdraw() external {
        uint256 amount = s_addressToAmountFunded[msg.sender];
        if (amount == 0) {
            revert FundMe__NoFundsAvailable();
        }

        uint256 timeRemaining = getTimeRemainingForWithdrawal(msg.sender);
        if (timeRemaining != 0) {
            revert FundMe__WithdrawalLocked();
        }

        // Reset the caller's fundings
        s_addressToAmountFunded[msg.sender] = 0;
        // Reset the caller's fundings list to empty
        delete s_fundingsByUser[msg.sender];
        // Reset the caller's contribution timestamps
        delete s_funderContributionsByTimestamp[msg.sender];

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FundMe__TransferFailed();
        emit Withdraw(msg.sender, amount);
    }

    /// @notice Returns the time remaining in seconds before the funder can withdraw.
    /// @dev Lock is based on the most recent contribution timestamp.
    ///      Returns 0 if the lock has expired. Reverts if the funder has no contributions.
    /// @param _funder The address to check the withdrawal lock for.
    /// @return The number of seconds until withdrawal is unlocked, or 0 if already unlocked.
    function getTimeRemainingForWithdrawal(
        address _funder
    ) public view returns (uint256) {
        uint256[] memory contributions = s_funderContributionsByTimestamp[
            _funder
        ];
        if (contributions.length == 0) {
            revert FundMe__NoContributionsFound();
        }

        // Use the most recent contribution timestamp to determine the unlock time
        uint256 lastContribution = contributions[contributions.length - 1];

        uint256 unlockTime = lastContribution + WITHDRAWAL_LOCK_DURATION;

        if (block.timestamp < unlockTime) {
            return unlockTime - block.timestamp;
        } else {
            return 0;
        }
    }

    /******************************************************************************
     *                          View / Getter Functions                           *
     ******************************************************************************/

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

    /// @notice Returns the version of the Chainlink price feed aggregator.
    /// @return The aggregator version number.
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    /// @notice Returns all contribution timestamps recorded for a funder.
    /// @param _funder The address to query.
    /// @return An array of block.timestamp values for each contribution made.
    function getFunderContributionsTimestamps(
        address _funder
    ) public view returns (uint256[] memory) {
        return s_funderContributionsByTimestamp[_funder];
    }

    /// @notice Returns all individual funding amounts for a funder in order.
    /// @param _funder The address to query.
    /// @return An array of ETH amounts in wei for each contribution made.
    function getFundingsByUser(
        address _funder
    ) public view returns (uint256[] memory) {
        return s_fundingsByUser[_funder];
    }

    /// @notice Returns the number of contributions made by a funder.
    /// @param _funder The address to query.
    /// @return The number of times the funder has called fund().
    function getFunderContributionsLength(
        address _funder
    ) public view returns (uint256) {
        return s_funderContributionsByTimestamp[_funder].length;
    }

    /// @notice Returns the Chainlink price feed interface used by this contract.
    /// @return The AggregatorV3Interface instance.
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
