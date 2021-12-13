import {
  deployContractByName,
  executeScript,
  mintFlow,
  sendTransaction
} from 'flow-js-testing';
import { getAdminAddress } from './util';

/*
 * Deploys Bnu contract to BnuAdmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployBnu = async () => {
  const BnuAdmin = await getAdminAddress();
  await mintFlow(BnuAdmin, '10.0');

  return deployContractByName({ to: BnuAdmin, name: 'BNU' });
};

/*
 * Setups Bnu Vault on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupBnuOnAccount = async (account) => {
  const name = 'bnu/setup_account';
  const signers = [account];

  return sendTransaction({ name, signers });
};

/*
 * Returns Bnu balance for **account**.
 * @param {string} account - account address
 * @throws Will throw an error if execution will be halted
 * @returns {UFix64}
 * */
export const getBnuBalance = async (account) => {
  const name = 'bnu/get_balance';
  const args = [account];

  return executeScript({ name, args });
};

/*
 * Returns Bnu supply.
 * @throws Will throw an error if execution will be halted
 * @returns {UFix64}
 * */
export const getBnuSupply = async () => {
  const name = 'bnu/get_supply';
  return executeScript({ name });
};

/*
 * Mints **amount** of Bnu tokens and transfers them to recipient.
 * @param {string} recipient - recipient address
 * @param {string} amount - UFix64 amount to mint
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const mintBnu = async (recipient, amount) => {
  const BnuAdmin = await getAdminAddress();

  const name = 'bnu/mint_tokens';
  const args = [recipient, amount];
  const signers = [BnuAdmin];

  return sendTransaction({ name, args, signers });
};

/*
 * Transfers **amount** of Bnu tokens from **sender** account to **recipient**.
 * @param {string} sender - sender address
 * @param {string} recipient - recipient address
 * @param {string} amount - UFix64 amount to transfer
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const transferBnu = async (sender, recipient, amount) => {
  const name = 'bnu/transfer_tokens';
  const args = [amount, recipient];
  const signers = [sender];

  return sendTransaction({ name, args, signers });
};
