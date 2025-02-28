# FundMe Smart Contract

A decentralized funding contract that allows users to contribute ETH with a time-locked withdrawal mechanism and price feed integration.

## Features

- Minimum contribution of 1 USD (in ETH equivalent)
- 2-minute time lock on withdrawals
- Chainlink Price Feed integration for ETH/USD conversion
- Tracking of individual contributions and timestamps
- Secure withdrawal mechanism

## Contract Functions

### Main Functions

- `fund()`: Contribute ETH (must meet minimum USD value)
- `withdraw()`: Withdraw your contributions after time lock expires
- `getTimeRemainingForWithdrawal(address)`: Check remaining lock time

### View Functions

- `getAddressToAmountFunded(address)`: Get total funded amount for an address
- `getVersion()`: Get price feed version
- `getFunderContributionsTimestamps(address)`: Get all contribution timestamps
- `getFundingsByUser(address)`: Get all funding amounts
- `getFunderContributionsLength(address)`: Get number of contributions
- `getPriceFeed()`: Get price feed contract address

## Constants

- `WITHDRAWAL_LOCK_DURATION`: 2 minutes
- `MINIMUM_USD`: 1 USD (scaled to 6 decimals)

## Events

- `Fund`: Emitted when funds are contributed
- `Withdraw`: Emitted when funds are withdrawn
- `ContributionsByFunder`: Emitted with contribution timestamps

## Development

### Testing Coverage

To generate and view test coverage:

**1. Generate coverage report:**

```bash
genhtml lcov.info -o coverage-report
```

**2. View the report:**

For macOS:

```bash
open coverage-report/index.html
```

For Linux:

```bash
xdg-open coverage-report/index.html
```

**\- You can use any IDE/editor lcov viewer extension to open the report.**

## Security Features

- Reentrancy protection
- Input validation
- Error handling with custom errors
- Precise timestamp tracking
- Secure withdrawal mechanism

## Dependencies

- Chainlink Price Feeds
