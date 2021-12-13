// @ts-check

import {
  deployContractByName,
  executeScript,
  mintFlow,
  sendTransaction
} from 'flow-js-testing';
import { getAdminAddress } from './util';

// AvatarArtNFT types
export const metadata = 'metadata.json';
/*
 * Deploys NonFungibleToken and AvatarArtNFT contracts to BnuAdmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployAvatarArtNFT = async () => {
  const BnuAdmin = await getAdminAddress();
  await mintFlow(BnuAdmin, '10.0');

  await deployContractByName({ to: BnuAdmin, name: 'NonFungibleToken' });

  const addressMap = { NonFungibleToken: BnuAdmin };
  return deployContractByName({
    to: BnuAdmin,
    name: 'AvatarArtNFT',
    addressMap
  });
};

/*
 * Setups AvatarArtNFT collection on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupAvatarArtNFTOnAccount = async (account) => {
  const name = 'avatar-art-nft/setup_account';
  const signers = [account];

  return sendTransaction({ name, signers });
};

/*
 * Returns AvatarArtNFT supply.
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64} - number of NFT minted so far
 * */
export const getAvatarArtNFTSupply = async () => {
  const name = 'avatar-art-nft/get_avatar_art_supply';

  return executeScript({ name });
};

/*
 * Mints Avatar Art NFT of a specific **itemType** and sends it to **recipient**.
 * @param {UInt64} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const mintAvatarArtNFT = async (metadata, recipient) => {
  const AdminAddr = await getAdminAddress();

  const name = 'avatar-art-nft/mint_nft';
  const args = [recipient, metadata];
  const signers = [AdminAddr];

  return sendTransaction({ name, args, signers });
};

/*
 * Transfers Avatar Art NFT with id equal **itemId** from **sender** account to **recipient**.
 * @param {string} sender - sender address
 * @param {string} recipient - recipient address
 * @param {UInt64} itemId - id of the item to transfer
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const transferAvatarArtNFT = async (sender, recipient, itemId) => {
  const name = 'avatar-art-nft/transfers';
  const args = [recipient, itemId];
  const signers = [sender];

  return sendTransaction({ name, args, signers });
};

/*
 * Returns the Avatar Art NFT with the provided **id** from an account collection.
 * @param {string} account - account address
 * @param {UInt64} itemID - NFT id
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getAvatarArt = async (account, itemID) => {
  const name = 'avatar-art-nft/get_avatar_art';
  const args = [account, itemID];

  return executeScript({ name, args });
};

/*
 * Returns the number of Avatar Art NFT in an account's collection.
 * @param {string} account - account address
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getAvatarArtCount = async (account) => {
  const name = 'avatar-art-nft/get_collection_length';
  const args = [account];

  return executeScript({ name, args });
};
