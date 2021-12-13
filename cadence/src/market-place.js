import { deployContractByName, sendTransaction } from 'flow-js-testing';
import {
  deployAvatarArtNFT,
  setupAvatarArtNFTOnAccount
} from './avatar-art-nft';
import { deployTransactionInfo } from './transaction-info';
import { getAdminAddress } from './util';

export const deployMarketplace = async () => {
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
    name: 'AvatarArtMarketplace',
    addressMap
  });
};

export const setupSaleCollectionForAccount = async (account) => {
  // Account shall be able to store kitty items and operate Kibbles
  await setupAvatarArtNFTOnAccount(account);
  const name = 'market/1_0_create_sale_collection';
  const signers = [account];

  return sendTransaction({ name, signers });
};

export const listForSale = async (seller, nftID, price) => {
  const name = 'market/2_0_list_for_sale';
  const signers = [seller];
  const args = [nftID, price];

  return sendTransaction({ name, signers, args });
};

export const unlistSale = async (seller, tokenId) => {
  const name = 'market/2_1_unlist_sale';
  const signers = [seller];
  const args = [tokenId];

  return sendTransaction({ name, signers, args });
};

export const purchase = async (buyer, seller, tokenId, buyAmount) => {
  const name = 'market/3_0_purchase';
  const signers = [buyer];
  const args = [seller, tokenId, buyAmount];

  return sendTransaction({ name, signers, args });
};
