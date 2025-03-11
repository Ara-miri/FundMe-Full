import { ethers } from "./ethers.min.js";
import {
  contractAbi,
  contractAddressOpSepolia,
  opSepoliaPriceFeedaddress,
} from "./constants.js";
import {
  handleConnectClick,
  liveChainChangeCheck,
  validateNetwork,
  TARGET_NETWORK,
} from "./switchNetworkHelper.js";

const provider = new ethers.BrowserProvider(window.ethereum);

let contract;
let signer;
let currentAccount;
let timeRemaining;

// DOM Elements
const connectButton = document.getElementById("connectButton");
const fundButton = document.getElementById("fundButton");
const withdrawButton = document.getElementById("withdrawButton");
const displayMessage = document.getElementById("displayMessage");

function formatTime(seconds) {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(remainingSeconds).padStart(2, "0")}`;
}

// Contract interaction functions
export async function initializeContract() {
  signer = await provider.getSigner();
  contract = new ethers.Contract(contractAddressOpSepolia, contractAbi, signer);
  currentAccount = await getWalletAddress();
  try {
    timeRemaining = Number(
      await contract.getTimeRemainingForWithdrawal(currentAccount)
    );
  } catch (error) {
    /* The error is expected for newly connected users/users that withdrawn their funds. Comes from the contract 
       getTimeRemainingForWithdrawal function */
    if (error.reason === "No contribution found for this address") {
      document.getElementById("userBalance").textContent = "0 ETH";
    }
  }
}

// Withdrawal timer management
async function updateWithdrawalTimer() {
  const timerDisplay = document.getElementById("withdrawalTimer");

  try {
    withdrawButton.disabled = timeRemaining > 0;
    timerDisplay.textContent =
      timeRemaining > 0 ? formatTime(timeRemaining) : "";
    timerDisplay.style.display = timeRemaining > 0 ? "inline" : "none";
    return timeRemaining;
  } catch (error) {
    console.error("Timer update failed:", error);
    withdrawButton.disabled = true;
    timerDisplay.textContent = "Error";
  }
}

// Core application initialization
async function initializeApplication() {
  // Checks chain changes and updates UI accordingly
  liveChainChangeCheck();

  // Set up periodic timer updates
  setInterval(async () => {
    if (currentAccount && contract && timeRemaining >= 0) {
      await updateWithdrawalTimer().then(--timeRemaining);
      console.log("Time remaining:", timeRemaining);
    }
  }, 1000);

  // Connect button handler
  connectButton.addEventListener("click", async () => {
    await handleConnectClick();
    if (!(await validateNetwork())) {
      return;
    }
    currentAccount = await getWalletAddress();
    // Initialize contract based on network
    await initializeContract();
    // To check user funded amount and display it
    await getUserBalance();
  });

  // Funding handler
  fundButton.addEventListener("click", handleFund);

  // Withdrawal handler
  withdrawButton.addEventListener("click", handleWithdraw);

  // Input validation
  document
    .getElementById("userAmountInput")
    .addEventListener("input", validateInput);
}

async function handleFund() {
  if (!(await validateNetwork())) return;

  const amountInput = document.getElementById("userAmountInput").value.trim();
  if (!validateAmount(amountInput)) return;

  try {
    const [minimumUsd, ethPrice] = await Promise.all([
      contract.MINIMUM_USD(),
      getEthPrice(),
    ]);

    const minEth = calculateMinimumEth(minimumUsd, ethPrice);

    if (Number(amountInput) < minEth) {
      alert(
        `Minimum funding: ${minEth.toFixed(6)} ETH ($${ethers.formatUnits(minimumUsd, 6)} USD)`
      );
      return;
    }

    const tx = await contract.fund({ value: ethers.parseEther(amountInput) });
    await tx.wait();

    displayMessage.innerHTML = `Deposit successful: <a href="${TARGET_NETWORK.config.blockExplorerUrls[0]}/tx/${tx.hash}" target="_blank">View transaction</a>`;
    await updateWithdrawalTimer();
    await getUserBalance();
  } catch (error) {
    console.error("Funding failed:", error);
    alert(error.shortMessage || "Transaction failed");
  }
}

async function handleWithdraw() {
  if (!(await validateNetwork())) return;
  if (!currentAccount) {
    alert("Please connect your wallet first.");
    return;
  }

  if ((await contract.getAddressToAmountFunded(currentAccount)) == 0) {
    alert("You don't have any funds to withdraw.");
    return;
  }

  try {
    const tx = await contract.withdraw();
    await tx.wait();

    displayMessage.innerHTML = `Withdrawal successful: <a href="${TARGET_NETWORK.explorer}/tx/${tx.hash}" target="_blank">View transaction</a>`;
    await getUserBalance();
  } catch (error) {
    console.error("Withdrawal failed:", error);
    alert(error.shortMessage || "Withdrawal failed");
  }
}

function validateInput(e) {
  e.target.value = e.target.value
    .replace(/[^0-9.]/g, "")
    .replace(/(\..*)\./g, "$1");
}

function validateAmount(amount) {
  if (!amount || isNaN(amount) || Number(amount) <= 0) {
    alert("Please enter a valid ETH amount");
    return false;
  }
  return true;
}

async function getEthPrice() {
  const priceFeed = new ethers.Contract(
    opSepoliaPriceFeedaddress,
    [
      "function latestRoundData() external view returns (uint80,int256,uint256,uint256,uint80)",
    ],
    provider
  );
  const roundData = await priceFeed.latestRoundData();
  const answer = roundData[1];
  return parseFloat(ethers.formatUnits(answer, 8));
}

function calculateMinimumEth(minimumUsd, ethPrice) {
  return parseFloat(ethers.formatUnits(minimumUsd, 6)) / ethPrice;
}

export async function getUserBalance() {
  try {
    const address = await getWalletAddress();
    const balance = await contract.getAddressToAmountFunded(address);
    document.getElementById("userBalance").innerHTML =
      `${ethers.formatEther(balance)} ETH`;
  } catch (error) {
    console.error("Balance check failed:", error);
  }
}

async function getWalletAddress() {
  const signer = await provider.getSigner();
  return signer.address;
}

// Start the application
initializeApplication();
