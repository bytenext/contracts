import { deployContractByName, sendTransaction } from 'flow-js-testing';
import {
  deployAvatarArtNFT,
  setupAvatarArtNFTOnAccount
} from './avatar-art-nft';
import { setupBnuOnAccount } from './bnu';
import { deployTransactionInfo } from './transaction-info';
import { getAdminAddress } from './util';

export const deployAuctionStore = async () => {
  const adminAddr = await getAdminAddress();

  await deployAvatarArtNFT();
  await deployTransactionInfo();

  const addressMap = {
    AvatarArtNFT: adminAddr,
    NonFungibleToken: adminAddr,
    AvatarArtTransactionInfo: adminAddr
  };

  return deployContractByName({
    to: adminAddr,
    name: 'AvatarArtAuction',
    addressMap
  });
};

/*
 * Sets up AvatarArtAuction.AuctionStore on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupAuctionStoreOnAccount = async (account) => {
  // Account shall be able to store kitty items and operate Kibbles
  await setupBnuOnAccount(account);
  await setupAvatarArtNFTOnAccount(account);

  const name = 'auctions/1_0_setup';
  const signers = [account];

  return sendTransaction({ name, signers });
};

export const setupFeePreference = async () => {
  const account = await getAdminAddress();
  const name = 'auctions/1_2_admin_setup_fee_reference';
  const signers = [account];
  const args = [account];

  return sendTransaction({ name, signers, args });
};

export const setupCurreniesAllow = async () => {
  const account = await getAdminAddress();
  const name = 'auctions/1_1_admin_setup_currencies_allow';
  const signers = [account];
  const addressMap = {
    BNU: account,
    AvatarArtTransactionInfo: account,
    FUSD: account
  };

  return sendTransaction({ name, signers, addressMap });
};

export const createAuction = async (
  seller,
  nftID,
  startTime,
  endTime,
  startPrice
) => {
  const name = 'auctions/2_0_create_auction';
  const signers = [seller];
  const args = [nftID, startTime, endTime, startPrice];

  return sendTransaction({ name, signers, args });
};

export const cancelAuction = async (seller, auctionID) => {
  const name = 'auctions/2_1_cancel_auction';
  const signers = [seller];
  const args = [auctionID];

  return sendTransaction({ name, signers, args });
};

export const placeBid = async (buyer, seller, auctionID, bidAmount) => {
  const name = 'auctions/3_0_place_bid';
  const signers = [buyer];
  const args = [seller, auctionID, bidAmount];

  return sendTransaction({ name, signers, args });
};

export const settleAuction = async (seller, auctionID) => {
  const name = 'auctions/4_0_settle_auction';
  const signers = [seller];
  const args = [auctionID];

  return sendTransaction({ name, signers, args });
};
