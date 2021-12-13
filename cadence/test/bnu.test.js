import path from 'path';

import {
  emulator,
  init,
  getAccountAddress,
  shallPass,
  shallResolve,
  shallRevert
} from 'flow-js-testing';
import {
  deployBnu,
  getBnuBalance,
  getBnuSupply,
  mintBnu,
  setupBnuOnAccount,
  transferBnu
} from '../src/bnu';
import { getAdminAddress, toUFix64 } from '../src/util';

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(500000);

describe('BNU', () => {
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

  it('shall have initialized supply field correctly', async () => {
    // Deploy contract
    await shallPass(deployBnu());

    await shallResolve(async () => {
      const [supply] = await getBnuSupply();
      expect(supply).toBe(toUFix64(0));
    });
  });

  it("shall be able to create empty Vault that doesn't affect supply", async () => {
    // Setup
    await deployBnu();
    const Alice = await getAccountAddress('Alice');
    await shallPass(setupBnuOnAccount(Alice));

    await shallResolve(async () => {
      const [supply] = await getBnuSupply();
      const [aliceBalance] = await getBnuBalance(Alice);
      expect(supply).toBe(toUFix64(0));
      expect(aliceBalance).toBe(toUFix64(0));
    });
  });

  it('shall not be able to mint zero tokens', async () => {
    // Setup
    await deployBnu();
    const Alice = await getAccountAddress('Alice');
    await setupBnuOnAccount(Alice);

    // Mint instruction with amount equal to 0 shall be reverted
    await shallRevert(mintBnu(Alice, toUFix64(0)));
  });

  it('shall mint tokens, deposit, and update balance and total supply', async () => {
    // Setup
    await deployBnu();
    const Alice = await getAccountAddress('Alice');
    await setupBnuOnAccount(Alice);
    const amount = toUFix64(50);

    // Mint BNU tokens for Alice
    await shallPass(mintBnu(Alice, amount));

    // Check BNU total supply and Alice's balance
    await shallResolve(async () => {
      // Check Alice balance to equal amount
      const [balance] = await getBnuBalance(Alice);
      expect(balance).toBe(amount);

      // Check BNU supply to equal amount
      const [supply] = await getBnuSupply();
      expect(supply).toBe(amount);
    });
  });

  it('shall not be able to withdraw more than the balance of the Vault', async () => {
    // Setup
    await deployBnu();
    const BnuAdmin = await getAdminAddress();
    const Alice = await getAccountAddress('Alice');
    await setupBnuOnAccount(BnuAdmin);
    await setupBnuOnAccount(Alice);

    // Set amounts
    const amount = toUFix64(1000);
    const overflowAmount = toUFix64(30000);

    // Mint instruction shall resolve
    await shallResolve(mintBnu(BnuAdmin, amount));

    // Transaction shall revert
    await shallRevert(transferBnu(BnuAdmin, Alice, overflowAmount));

    // Balances shall be intact
    await shallResolve(async () => {
      const [aliceBalance] = await getBnuBalance(Alice);
      expect(aliceBalance).toBe(toUFix64(0));

      const [BnuAdminBalance] = await getBnuBalance(BnuAdmin);
      expect(BnuAdminBalance).toBe(amount);
    });
  });

  it('shall be able to withdraw and deposit tokens from a Vault', async () => {
    await deployBnu();
    const BnuAdmin = await getAdminAddress();
    const Alice = await getAccountAddress('Alice');
    await setupBnuOnAccount(BnuAdmin);
    await setupBnuOnAccount(Alice);
    await mintBnu(BnuAdmin, toUFix64(1000));

    await shallPass(transferBnu(BnuAdmin, Alice, toUFix64(300)));

    await shallResolve(async () => {
      // Balances shall be updated
      const [BnuAdminBalance] = await getBnuBalance(BnuAdmin);
      expect(BnuAdminBalance).toBe(toUFix64(700));

      const [aliceBalance] = await getBnuBalance(Alice);
      expect(aliceBalance).toBe(toUFix64(300));

      const [supply] = await getBnuSupply();
      expect(supply).toBe(toUFix64(1000));
    });
  });
});
