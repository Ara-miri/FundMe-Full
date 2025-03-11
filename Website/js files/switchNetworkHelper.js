import {
  optimismSepoliaChain,
  contractAbi,
  contractAddressOpSepolia,
} from "./constants.js";
import { getUserBalance, initializeContract } from "./index.js";
import { ethers } from "./ethers.min.js";

/**
 * Target network configuration.
 */
export const TARGET_NETWORK = {
  chainId: Number(optimismSepoliaChain.chainId),
  config: optimismSepoliaChain,
};
/**
 * Checks if user has metamask installed. Then checks and handles the network correctness,
 * and updates the UI connect button based on connected network.
 */
export async function handleConnectClick() {
  if (!window.ethereum) {
    window.open("https://metamask.io", "_blank");
    return;
  }

  try {
    const connectButton = document.getElementById("connectButton");
    connectButton.innerHTML = "Connecting...";

    if (!(await validateNetwork())) {
      connectButton.innerHTML = "Switching Network...";
      await switchNetwork(TARGET_NETWORK);
    }

    await window.ethereum.request({ method: "eth_requestAccounts" });
    await updateConnectButtonStatus();
    await getUserBalance();
  } catch (error) {
    console.error("Connection failed:", error);
    updateConnectButtonStatus();
  }
}

// Event handlers
function handleChainChanged(chainIdHex) {
  const chainId = parseInt(chainIdHex, 16);
  updateConnectButtonStatus();

  if (chainId !== TARGET_NETWORK.chainId) {
    console.log("Network changed to unsupported chain");
  }
}

// UI management
async function updateConnectButtonStatus() {
  const connectButton = document.getElementById("connectButton");
  const isValidNetwork = await validateNetwork();

  connectButton.innerHTML = isValidNetwork
    ? "✅ Connected"
    : "⚠️ Wrong Network";
  connectButton.style.backgroundColor = isValidNetwork ? "#4CAF50" : "#ffd700";

  if (isValidNetwork) await initializeContract();
}

export async function validateNetwork() {
  const currentChainId = await getCurrentChainId();
  return currentChainId === TARGET_NETWORK.chainId;
}

// Network status handling
async function getCurrentChainId() {
  const chainIdHex = await window.ethereum.request({ method: "eth_chainId" });
  return parseInt(chainIdHex, 16);
}

async function addNetwork(chainConfig) {
  try {
    await window.ethereum.request({
      method: "wallet_addEthereumChain",
      params: [chainConfig],
    });
    return true;
  } catch (error) {
    if (error.code === 4001) return false;
    return true; // Already exists
  }
}

async function switchNetwork(targetChain) {
  try {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: targetChain.config.chainId }],
    });
    return true;
  } catch (error) {
    if (error.code === 4902) {
      return await addNetwork(targetChain.config);
    }
    console.error("Network switch failed:", error);
    return false;
  }
}

export function liveChainChangeCheck() {
  if (window.ethereum) {
    window.ethereum.on("chainChanged", handleChainChanged);
    updateConnectButtonStatus();
  }
}
