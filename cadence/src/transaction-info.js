import { deployContractByName, mintFlow } from 'flow-js-testing';
import { getAdminAddress } from './util';

/*
 * Deploys Bnu contract to BnuAdmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployTransactionInfo = async () => {
  const BnuAdmin = await getAdminAddress();
  await mintFlow(BnuAdmin, '10.0');

  return deployContractByName({
    to: BnuAdmin,
    name: 'AvatarArtTransactionInfo'
  });
};

export const deployFungibleToken = async () => {
  const BnuAdmin = await getAdminAddress();
  await mintFlow(BnuAdmin, '10.0');

  return deployContractByName({
    to: BnuAdmin,
    name: 'FungibleToken'
  });
};

export const deployFUSD = async () => {
  const BnuAdmin = await getAdminAddress();
  await mintFlow(BnuAdmin, '10.0');

  return deployContractByName({
    to: BnuAdmin,
    name: 'FUSD'
  });
};
