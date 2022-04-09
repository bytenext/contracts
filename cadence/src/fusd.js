import {
  deployContractByName,
  executeScript,
  mintFlow,
  sendTransaction
} from "flow-js-testing";
import { getAdminAddress } from "./util";

/*
 * Deploys Fusd contract to FusdAdmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployFusd = async () => {
  const FusdAdmin = await getAdminAddress();
  await mintFlow(FusdAdmin, "10.0");

  return deployContractByName({ to: FusdAdmin, name: "FUSD" });
};

/*
 * Setups Fusd Vault on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupFusdOnAccount = async (account) => {
  const name = "fusd/setup_account";
  const signers = [account];

  return sendTransaction({ name, signers });
};

/*
 * Returns Fusd balance for **account**.
 * @param {string} account - account address
 * @throws Will throw an error if execution will be halted
 * @returns {UFix64}
 * */
export const getFusdBalance = async (account) => {
  const name = "fusd/get_balance";
  const args = [account];

  return executeScript({ name, args });
};

/*
 * Returns Fusd supply.
 * @throws Will throw an error if execution will be halted
 * @returns {UFix64}
 * */
export const getFusdSupply = async () => {
  const name = "fusd/get_supply";
  return executeScript({ name });
};

/*
 * Mints **amount** of Fusd tokens and transfers them to recipient.
 * @param {string} recipient - recipient address
 * @param {string} amount - UFix64 amount to mint
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const mintFusd = async (recipient, amount) => {
  const FusdAdmin = await getAdminAddress();

  const name = "fusd/mint_tokens";
  const args = [recipient, amount];
  const signers = [FusdAdmin];

  return sendTransaction({ name, args, signers });
};

/*
 * Transfers **amount** of Fusd tokens from **sender** account to **recipient**.
 * @param {string} sender - sender address
 * @param {string} recipient - recipient address
 * @param {string} amount - UFix64 amount to transfer
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const transferFusd = async (sender, recipient, amount) => {
  const name = "fusd/transfer_tokens";
  const args = [amount, recipient];
  const signers = [sender];

  return sendTransaction({ name, args, signers });
};
