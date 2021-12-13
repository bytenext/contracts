import {
  deployContractByName,
  executeScript,
  sendTransaction
} from 'flow-js-testing';
import { getAdminAddress } from './util';
import { deployBnu } from './bnu';

export const deployStaking = async (rewardPerBlock, startBlock, endBlock) => {
  const addr = await getAdminAddress();
  await deployBnu();

  const args = [rewardPerBlock, startBlock, endBlock];
  const addressMap = {
    BNU: addr
  };

  return deployContractByName({
    to: addr,
    name: 'ByteNextStaking',
    args,
    addressMap
  });
};

export const deposit = async (account, amount) => {
  const name = 'staking/deposit';
  const signers = [account];
  const args = [amount];

  return sendTransaction({ name, signers, args });
};

export const withdraw = async (account, amount) => {
  const name = 'staking/withdraw';
  const signers = [account];
  const args = [amount];

  return sendTransaction({ name, signers, args });
};

export const depositRewardPool = async (account, amount) => {
  const name = 'staking/adminDepositRewards';
  const signers = [account];
  const args = [amount];

  return sendTransaction({ name, signers, args });
};

export const withRewardPool = async (account, amount) => {
  const name = 'staking/adminWithdrawRewardPool';
  const signers = [account];
  const args = [account, amount];

  return sendTransaction({ name, signers, args });
};

export const getUserStakeInfo = async (account) => {
  const name = 'staking/getUserStakeInfo';
  const args = [account];

  return executeScript({ name, args });
};

export const getStakeVaultBalances = async () => {
  const name = 'staking/getStakeVaultBalances';

  return executeScript({ name });
};

export const getStakePoolInfo = async () => {
  const name = 'staking/getStakePoolInfo';

  return executeScript({ name });
};
