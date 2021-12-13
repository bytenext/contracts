import {
  deployContractByName,
  executeScript,
  sendTransaction
} from 'flow-js-testing';
import { getAdminAddress } from './util';

export const deployLaunchpad = async () => {
  const addr = await getAdminAddress();

  return deployContractByName({
    to: addr,
    name: 'ByteNextLaunchpad'
  });
};

export const createNewLaunchpad = (
  admin,
  startTime,
  endTime,
  tokenPrice,
  receiverAddr,
  claimingTimes,
  claimingPercents,
  totalRaise
) => {
  const name = 'launchpad/createNewLaunchpad';
  const signers = [admin];
  const args = [
    startTime,
    endTime,
    tokenPrice,
    receiverAddr,
    claimingTimes,
    claimingPercents,
    totalRaise
  ];

  return sendTransaction({ name, signers, args });
};

export const depositLaunchpadToken = (admin, padId, amount) => {
  const name = 'launchpad/depositLaunchpadToken';
  const signers = [admin];
  const args = [padId, amount];

  return sendTransaction({ name, signers, args });
};

export const setUserAllocation = (admin, id, address, allocation) => {
  const name = 'launchpad/setUserAllocation';
  const signers = [admin];
  const args = [id, address, allocation];

  return sendTransaction({ name, signers, args });
};

export const withdrawLaunchpadToken = (
  admin,
  padAddress,
  padId,
  receiver,
  amount
) => {
  const name = 'launchpad/withdrawLaunchpadToken';
  const signers = [admin];
  const args = [padAddress, padId, receiver, amount];

  return sendTransaction({ name, signers, args });
};

export const joinToLaunchpad = async (user, padAddress, padId, amount) => {
  const name = 'launchpad/join-bnu';
  const signers = [user];
  const args = [padAddress, padId, amount];

  return sendTransaction({ name, signers, args });
};

export const claimLaunchpad = (user, padAddress, padId) => {
  const name = 'launchpad/claim';
  const signers = [user];
  const args = [padAddress, padId];

  return sendTransaction({ name, signers, args });
};

export const getClaimable = (user, padAddress, padId) => {
  const name = 'launchpad/getClaimable';
  const args = [padAddress, padId, user];

  return executeScript({ name, args });
};

export const getClaimInfo = (user, padAddress, padId) => {
  const name = 'launchpad/getClaimInfo';
  const args = [padAddress, padId, user];

  return executeScript({ name, args });
};

export const getLaunchpadInfo = (padAddress, padId) => {
  const name = 'launchpad/getLaunchpadInfo';
  const args = [padAddress, padId];

  return executeScript({ name, args });
};

export const getLaunchpadTokenSold = (padAddress, padId) => {
  const name = 'launchpad/getLaunchpadTokenSold';
  const args = [padAddress, padId];

  return executeScript({ name, args });
};

export const getUserAllocation = (user, padAddress, padId) => {
  const name = 'launchpad/getUserAllocation';
  const args = [padAddress, padId, user];

  return executeScript({ name, args });
};

export const getUserPurchased = (user, padAddress, padId) => {
  const name = 'launchpad/getUserPurchased';
  const args = [padAddress, padId, user];

  return executeScript({ name, args });
};
