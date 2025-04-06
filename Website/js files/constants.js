export const contractAbi = [
  { type: "fallback", stateMutability: "payable" },
  { type: "receive", stateMutability: "payable" },
  {
    type: "function",
    name: "MINIMUM_USD",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "WITHDRAWAL_LOCK_DURATION",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "fund",
    inputs: [],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "getAddressToAmountFunded",
    inputs: [
      {
        name: "fundingAddress",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getFunderContributionsLength",
    inputs: [{ name: "_funder", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getFunderContributionsTimestamps",
    inputs: [{ name: "_funder", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "uint256[]", internalType: "uint256[]" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getFundingsByUser",
    inputs: [{ name: "_funder", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "uint256[]", internalType: "uint256[]" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getNewValue",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getPriceFeed",
    inputs: [],
    outputs: [{ name: "", type: "address", internalType: "address" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getTimeRemainingForWithdrawal",
    inputs: [{ name: "_funder", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getVersion",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "initialize",
    inputs: [{ name: "priceFeed", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setNewValue",
    inputs: [{ name: "_value", type: "uint256", internalType: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "withdraw",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "ContributionsByFunder",
    inputs: [
      {
        name: "funder",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "contributions",
        type: "uint256[]",
        indexed: false,
        internalType: "uint256[]",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Fund",
    inputs: [
      {
        name: "funder",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Initialized",
    inputs: [
      {
        name: "version",
        type: "uint64",
        indexed: false,
        internalType: "uint64",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "NewValueSet",
    inputs: [
      {
        name: "newValue",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Withdraw",
    inputs: [
      {
        name: "recipient",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  { type: "error", name: "FundMe__InsufficientFunds", inputs: [] },
  { type: "error", name: "FundMe__NoContributionsFound", inputs: [] },
  { type: "error", name: "FundMe__NoFundsAvailable", inputs: [] },
  { type: "error", name: "FundMe__TransferFailed", inputs: [] },
  { type: "error", name: "FundMe__WithdrawalLocked", inputs: [] },
  { type: "error", name: "InvalidInitialization", inputs: [] },
  { type: "error", name: "NotInitializing", inputs: [] },
];

export const sepoliaChain = {
  chainId: "0xaa36a7", // 11155111 in hex
  chainName: "Sepolia Test Network",
  nativeCurrency: {
    name: "Sepolia ETH",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: ["https://rpc.sepolia.org"],
  blockExplorerUrls: ["https://sepolia.etherscan.io"],
};
export const optimismSepoliaChain = {
  chainId: "0xaa37dc", // 11155420 in hex
  chainName: "OP Sepolia Testnet",
  nativeCurrency: {
    name: "Optimism Sepolia ETH",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: ["https://sepolia.optimism.io"],
  blockExplorerUrls: ["https://sepolia-optimistic.etherscan.io"],
};

export const contractAddressOpSepolia =
  "0xA75c5adA5aacFa9BC4c5DDA45B4d9975fE1AF5B1"; // proxy deployed at "network optimism sepolia"

export const opSepoliaPriceFeedaddress =
  "0x61Ec26aA57019C486B10502285c5A3D4A4750AD7"; // Optimism Sepolia ETH/USD feed
