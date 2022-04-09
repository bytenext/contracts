import {
  emulator,
  getAccountAddress,
  init,
  shallPass,
  shallResolve,
  shallRevert
} from 'flow-js-testing';
import path from 'path';
import { getBnuBalance, mintBnu, setupBnuOnAccount } from '../src/bnu';
import {
  deployStaking,
  deposit,
  depositRewardPool,
  getStakePoolInfo,
  getUserStakeInfo,
  withdraw,
  withRewardPool
} from '../src/staking';
import {
  getAdminAddress,
  getBlockHeight,
  sleep,
  toUFix64,
  tx
} from '../src/util';

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(500000);

describe('ByteNextStaking', () => {
  // Instantiate emulator and path to Cadence files
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../cadence');
    const port = 7001;
    await init(basePath, { port }); emulator.setLogging(true);
    return emulator.start(port, false);
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  it('shall have initialized field correctly', async () => {
    // Deploy contract
    const startBlock = await getBlockHeight();
    await shallPass(tx(deployStaking(0.05, +startBlock, +startBlock + 10)));

    await shallResolve(async () => {
      const [{ totalStaked, rewardPerBlock }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(0));
      expect(rewardPerBlock).toBe(toUFix64(0.05));
    });
  });

  it('shall only admin can deposit to rewards pool', async () => {
    const startBlock = await getBlockHeight();
    await shallPass(tx(deployStaking(0.05, +startBlock, +startBlock + 10)));

    const addminAddr = await getAdminAddress();
    await setupBnuOnAccount(addminAddr);
    await mintBnu(addminAddr, 1000);

    const Alice = await getAccountAddress('alice');
    await setupBnuOnAccount(Alice);
    await mintBnu(Alice, 1000);

    await shallRevert(depositRewardPool(Alice, 1000));
    await shallPass(depositRewardPool(addminAddr, 1000));
  });

  it('shall only admin can withdraw from rewards pool directly', async () => {
    const startBlock = await getBlockHeight();
    await shallPass(tx(deployStaking(0.05, +startBlock, +startBlock + 10)));

    const adminAddr = await getAdminAddress();
    await setupBnuOnAccount(adminAddr);
    await mintBnu(adminAddr, 1000);

    const Alice = await getAccountAddress('alice');
    await setupBnuOnAccount(Alice);
    await mintBnu(Alice, 1000);

    await shallPass(tx(depositRewardPool(adminAddr, 1000)));

    await shallRevert(withRewardPool(Alice, 1000));
    await shallPass(tx(withRewardPool(adminAddr, 1000)));
  });

  it('shall have desposit BNU to pool correctly', async () => {
    // Deploy contract
    const startBlock = await getBlockHeight();
    await shallPass(tx(deployStaking(0.05, +startBlock, +startBlock + 10)));

    await shallResolve(async () => {
      const [{ totalStaked, rewardPerBlock }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(0));
      expect(rewardPerBlock).toBe(toUFix64(0.05));
    });

    const Alice = await getAccountAddress('alice');
    await setupBnuOnAccount(Alice);
    await mintBnu(Alice, 1000);

    await shallResolve(async () => {
      const [, error] = await deposit(Alice, 1000);
      expect(error).toBeNull();

      const [{ totalStaked }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(1000));

      const [{ stakingAmount }] = await getUserStakeInfo(Alice);
      expect(stakingAmount).toBe(toUFix64(1000));
    });
  });

  it('shall have withdraw BNU from pool correctly', async () => {
    // Deploy contract
    const startBlock = await getBlockHeight();
    await shallPass(tx(deployStaking(10, +startBlock, +startBlock + 100)));

    // Deposit rewards to pool
    const admin = await getAdminAddress();
    await setupBnuOnAccount(admin);
    await mintBnu(admin, 1000);
    await shallPass(tx(depositRewardPool(admin, 1000)));

    await shallResolve(async () => {
      const [{ totalStaked, rewardPerBlock }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(0));
      expect(rewardPerBlock).toBe(toUFix64(10));
    });

    const Alice = await getAccountAddress('alice');
    await setupBnuOnAccount(Alice);
    await mintBnu(Alice, 1000);

    await shallResolve(async () => {
      // Deposit 1000 BNU to pool
      let [, error] = await deposit(Alice, 1000);
      expect(error).toBeNull();

      // Withdraw 1001 BNU from pool
      [, error] = await withdraw(Alice, 1001);
      expect(error).toContain('withdraw: Amount invalid');

      let [{ totalStaked }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(1000));

      // Wait and mint other transaction to increase block height
      await sleep(1000);
      await mintBnu(admin, 1000);

      let [{ stakingAmount, pendingReward }] = await getUserStakeInfo(Alice);

      [, error] = await withdraw(Alice, 1000);
      expect(error).toBeNull();

      [{ totalStaked }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(0));

      [{ stakingAmount, pendingReward }] = await getUserStakeInfo(Alice);
      expect(stakingAmount).toBe(toUFix64(0));
      expect(pendingReward).toBe(toUFix64(0));

      const [aliceBalance] = await getBnuBalance(Alice);
      expect(+aliceBalance).toBeGreaterThan(1000);
    });
  });

  it('shall not have rewards when pool not started', async () => {
    // Deploy contract
    const startBlock = await getBlockHeight();
    await shallPass(
      tx(deployStaking(10, +startBlock + 200, +startBlock + 300))
    );

    // Deposit rewards to pool
    const admin = await getAdminAddress();
    await setupBnuOnAccount(admin);
    await mintBnu(admin, 1000);
    await shallPass(tx(depositRewardPool(admin, 1000)));

    await shallResolve(async () => {
      const [{ totalStaked, rewardPerBlock }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(0));
      expect(rewardPerBlock).toBe(toUFix64(10));
    });

    const Alice = await getAccountAddress('alice');
    await setupBnuOnAccount(Alice);
    await mintBnu(Alice, 1000);

    await shallResolve(async () => {
      // Deposit 1000 BNU to pool
      let [, error] = await deposit(Alice, 1000);
      expect(error).toBeNull();

      let [{ totalStaked }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(1000));

      // Wait and mint other transaction to increase block height
      await sleep(1000);
      await mintBnu(admin, 1000);

      let [{ stakingAmount, pendingReward }] = await getUserStakeInfo(Alice);

      [{ stakingAmount, pendingReward }] = await getUserStakeInfo(Alice);
      expect(stakingAmount).toBe(toUFix64(1000));
      expect(pendingReward).toBe(toUFix64(0));

      [, error] = await withdraw(Alice, 1000);
      expect(error).toBeNull();

      [{ totalStaked }] = await getStakePoolInfo();
      expect(totalStaked).toBe(toUFix64(0));

      [{ stakingAmount, pendingReward }] = await getUserStakeInfo(Alice);
      expect(stakingAmount).toBe(toUFix64(0));
      expect(pendingReward).toBe(toUFix64(0));

      const [aliceBalance] = await getBnuBalance(Alice);
      expect(aliceBalance).toBe(toUFix64(1000));
    });
  });
});
