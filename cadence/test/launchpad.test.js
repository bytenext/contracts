import {
  emulator,
  getAccountAddress,
  getFlowBalance,
  init,
  mintFlow,
  shallPass,
  shallResolve,
  shallRevert
} from 'flow-js-testing';
import path from 'path';
import { deployBnu, mintBnu, setupBnuOnAccount } from '../src/bnu';
import {
  claimLaunchpad,
  createNewLaunchpad,
  deployLaunchpad,
  depositLaunchpadToken,
  getClaimable,
  getLaunchpadInfo,
  getUserAllocation,
  getUserPurchased,
  joinToLaunchpad,
  setUserAllocation,
  withdrawLaunchpadToken
} from '../src/launchpad';
import {
  getAdminAddress,
  getCurrentTimestamp,
  toUFix64,
  tx,
  waitToTimeOver as waitToTimeOver
} from '../src/util';

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(500000);

describe('ByteNext Launchpad', () => {
  // Instantiate emulator and path to Cadence files
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../cadence');
    const port = 7001;
    await init(basePath, { port });
    return emulator.start(port, false);
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  it('shall have deploy correctly', async () => {
    // Deploy contract
    await shallPass(tx(deployLaunchpad()));
  });

  it('shall have create launchpad correctly', async () => {
    const admin = await getAdminAddress();

    // Deploy contract
    await shallPass(tx(deployLaunchpad()));
    await shallPass(deployBnu());
    await setupBnuOnAccount(admin);

    const now = await getCurrentTimestamp();
    const claimingTimes = [toUFix64(+now + 50), toUFix64(+now + 70)];
    const claimingPercents = [toUFix64(40), toUFix64(60)];

    await shallPass(
      tx(
        createNewLaunchpad(
          admin,
          +now,
          +now + 30,
          5.0,
          admin,
          claimingTimes,
          claimingPercents,
          10000
        )
      )
    );

    await shallResolve(async () => {
      const [info] = await getLaunchpadInfo(admin, 1);
      expect(info).not.toBeNull();
    });
  });

  it('shall deposit and withdraw launchpad token correctly by admin', async () => {
    const admin = await getAdminAddress();

    // Deploy contract
    await shallPass(tx(deployLaunchpad()));
    await shallPass(deployBnu());
    await setupBnuOnAccount(admin);

    const now = await getCurrentTimestamp();
    const claimingTimes = [toUFix64(+now + 50), toUFix64(+now + 70)];
    const claimingPercents = [toUFix64(40), toUFix64(60)];

    await shallPass(
      tx(
        createNewLaunchpad(
          admin,
          +now,
          +now + 30,
          5.0,
          admin,
          claimingTimes,
          claimingPercents,
          10000
        )
      )
    );

    await shallResolve(async () => {
      const [info] = await getLaunchpadInfo(admin, 1);
      expect(info).not.toBeNull();
    });

    const alice = await getAccountAddress('alice');
    await mintFlow(alice, 1000);
    shallRevert(tx(depositLaunchpadToken(alice, 1, 200)));

    await mintFlow(admin, 1000);
    await shallPass(tx(depositLaunchpadToken(admin, 1, 200)));

    await shallRevert(tx(withdrawLaunchpadToken(admin, admin, 1, admin, 300)));
    await shallPass(tx(withdrawLaunchpadToken(admin, admin, 1, admin, 100)));
  });

  it('shall set user allocation correctly  by admin', async () => {
    const admin = await getAdminAddress();

    // Deploy contract
    await shallPass(tx(deployLaunchpad()));
    await shallPass(deployBnu());
    await setupBnuOnAccount(admin);

    const now = await getCurrentTimestamp();
    const claimingTimes = [toUFix64(+now + 50), toUFix64(+now + 70)];
    const claimingPercents = [toUFix64(40), toUFix64(60)];

    await shallPass(
      tx(
        createNewLaunchpad(
          admin,
          +now,
          +now + 30,
          5.0,
          admin,
          claimingTimes,
          claimingPercents,
          10000
        )
      )
    );

    await shallResolve(async () => {
      const [info] = await getLaunchpadInfo(admin, 1);
      expect(info).not.toBeNull();
    });

    const alice = await getAccountAddress('alice');

    // Only admin can do this, other can not
    await shallRevert(tx(setUserAllocation(alice, 1, alice, 5000)));
    await shallPass(tx(setUserAllocation(admin, 1, alice, 5000)));

    await shallResolve(async () => {
      const [allocation] = await getUserAllocation(alice, admin, 1);
      expect(allocation).toBe(toUFix64(5000));
    });
  });

  it('shall guarantee user can join launchpad only when pool has started', async () => {
    const admin = await getAdminAddress();

    // Deploy contract
    await shallPass(tx(deployLaunchpad()));
    await shallPass(deployBnu());
    await setupBnuOnAccount(admin);

    const now = await getCurrentTimestamp();
    const claimingTimes = [toUFix64(+now + 50), toUFix64(+now + 70)];
    const claimingPercents = [toUFix64(40), toUFix64(60)];
    const startTime = +now + 10;
    const endTime = +now + 100;
    const price = 5;

    await shallPass(
      tx(
        createNewLaunchpad(
          admin,
          startTime,
          endTime,
          price,
          admin,
          claimingTimes,
          claimingPercents,
          10000
        )
      )
    );

    const alice = await getAccountAddress('alice');
    await setupBnuOnAccount(alice);
    await mintBnu(alice, 10000);

    const allocation = 5000;
    const padID = 1;

    await shallResolve(async () => {
      const [info] = await getLaunchpadInfo(admin, padID);
      expect(info).not.toBeNull();
      await tx(setUserAllocation(admin, 1, alice, allocation));
    });

    let [, error] = await joinToLaunchpad(alice, admin, padID, allocation);
    expect(error).toContain('Can not join this launchpad at this time');

    await waitToTimeOver(+now + 12);
    expect(+(await getCurrentTimestamp())).toBeGreaterThan(startTime);

    [, error] = await joinToLaunchpad(alice, admin, padID, allocation);
    expect(error).toBeNull();

    await shallResolve(async () => {
      const [purchased] = await getUserPurchased(alice, admin, padID);
      expect(purchased.tokenPaid).toBe(toUFix64(allocation));

      const [claimable] = await getClaimable(alice, admin, padID);

      // Cause by pad not ended
      expect(claimable).toBe(toUFix64(0));
    });
  });

  it('shall guarantee user in whitelist which can buy less than or equal their allocation', async () => {
    const admin = await getAdminAddress();

    // Deploy contract
    await shallPass(tx(deployLaunchpad()));
    await shallPass(deployBnu());
    await setupBnuOnAccount(admin);

    const now = await getCurrentTimestamp();
    const claimingTimes = [toUFix64(+now + 50), toUFix64(+now + 70)];
    const claimingPercents = [toUFix64(40), toUFix64(60)];
    const startTime = +now + 2;
    const endTime = +now + 100;
    const price = 5;

    await shallPass(
      tx(
        createNewLaunchpad(
          admin,
          startTime,
          endTime,
          price,
          admin,
          claimingTimes,
          claimingPercents,
          10000
        )
      )
    );

    const alice = await getAccountAddress('alice');
    await setupBnuOnAccount(alice);
    await mintBnu(alice, 10000);

    const allocation = 5000;
    const padID = 1;

    await shallResolve(async () => {
      const [info] = await getLaunchpadInfo(admin, padID);
      expect(info).not.toBeNull();
    });

    await waitToTimeOver(startTime + 1);
    expect(+(await getCurrentTimestamp())).toBeGreaterThan(startTime);

    let [, error] = await joinToLaunchpad(alice, admin, padID, 1);
    expect(error).toContain('You can not join this launchpad');

    await tx(setUserAllocation(admin, 1, alice, allocation));
    [, error] = await joinToLaunchpad(alice, admin, padID, allocation + 20);
    expect(error).toContain('Out of allocation');

    [, error] = await joinToLaunchpad(alice, admin, padID, allocation);
    expect(error).toBeNull();

    await shallResolve(async () => {
      const [purchased] = await getUserPurchased(alice, admin, padID);
      expect(purchased.tokenPaid).toBe(toUFix64(allocation));

      const [claimable] = await getClaimable(alice, admin, padID);

      // Cause by pad not ended
      expect(claimable).toBe(toUFix64(0));
    });
  });

  it('shall guarantee user which alreay bought can claim at claim time', async () => {
    const admin = await getAdminAddress();

    // Deploy contract
    await shallPass(tx(deployLaunchpad()));
    await shallPass(deployBnu());
    await setupBnuOnAccount(admin);

    const now = await getCurrentTimestamp();
    const startTime = +now + 2;
    const endTime = +now + 10;
    const price = 5;
    const claimingTimes = [toUFix64(endTime + 4), toUFix64(endTime + 10)];
    const claimingPercents = [toUFix64(40), toUFix64(60)];

    await shallPass(
      tx(
        createNewLaunchpad(
          admin,
          startTime,
          endTime,
          price,
          admin,
          claimingTimes,
          claimingPercents,
          10000
        )
      )
    );

    const alice = await getAccountAddress('alice');
    await setupBnuOnAccount(alice);
    await mintBnu(alice, 10000);
    await mintFlow(alice, 1000);

    const allocation = 5000;
    const padID = 1;

    await shallResolve(async () => {
      const [info] = await getLaunchpadInfo(admin, padID);
      expect(info).not.toBeNull();
    });

    mintFlow(admin, 1000000);
    await shallPass(tx(depositLaunchpadToken(admin, padID, 100000)));

    await waitToTimeOver(startTime + 2);
    expect(+(await getCurrentTimestamp())).toBeGreaterThan(startTime);

    await tx(setUserAllocation(admin, 1, alice, allocation));
    let [, error] = await joinToLaunchpad(alice, admin, padID, allocation);
    expect(error).toBeNull();

    [, error] = await claimLaunchpad(alice, admin, padID);
    expect(error).toContain(
      'Can not claim token of this launchpad at this time'
    );

    await shallResolve(async () => {
      const [purchased] = await getUserPurchased(alice, admin, padID);
      expect(purchased.tokenPaid).toBe(toUFix64(allocation));

      let [claimable] = await getClaimable(alice, admin, padID);
      // Cause by pad not ended
      expect(claimable).toBe(toUFix64(0));

      await waitToTimeOver(claimingTimes[0]);
      [claimable] = await getClaimable(alice, admin, padID);

      // Cause by pad not ended
      const bought = +purchased.purchased;
      expect(claimable).toBe(toUFix64((claimingPercents[0] * bought) / 100));

      const [flowBalance] = await getFlowBalance(alice);
      [, error] = await claimLaunchpad(alice, admin, padID);

      const [newBalance] = await getFlowBalance(alice);
      expect(error).toBeNull();
      expect(newBalance).toBe(toUFix64(+flowBalance + +claimable));
    });
  });
});
