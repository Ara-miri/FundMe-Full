export const contractAbi = [
  {
    type: "constructor",
    inputs: [{ name: "priceFeed", type: "address", internalType: "address" }],
    stateMutability: "nonpayable",
  },
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
    name: "getPriceFeed",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "contract AggregatorV3Interface",
      },
    ],
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
  { type: "error", name: "FundMe__NotOwner", inputs: [] },
  { type: "error", name: "FundMe__TransferFailed", inputs: [] },
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
export const contractAddressSepolia =
  "0xdadaD79811F69c8F520f18d2b6B04F7f25ED467d"; // deployed at "network sepolia"
export const contractAddressOpSepolia =
  "0x80339D6B6fD991e702eDE4F489dEd6b99DA804a7"; // deployed at "network optimism sepolia"

export const opSepoliaPriceFeedaddress =
  "0x61Ec26aA57019C486B10502285c5A3D4A4750AD7"; // Optimism Sepolia ETH/USD feed
export const sepoliaPriceFeedaddress =
  "0x694AA1769357215DE4FAC081bf1f309aDC325306"; // Sepolia ETH/USD feed
