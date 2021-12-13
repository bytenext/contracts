import {
  emulator,
  getAccountAddress,
  init,
  shallPass,
  shallResolve,
  shallRevert
} from 'flow-js-testing';
import path from 'path';
import {
  deployAvatarArtNFT,
  getAvatarArtCount,
  getAvatarArtNFTSupply,
  mintAvatarArtNFT,
  setupAvatarArtNFTOnAccount,
  transferAvatarArtNFT,
  metadata
} from '../src/avatar-art-nft';
import { getAdminAddress, sansPrefix } from '../src/util';

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(50000);

describe('Avatar Art NFT', () => {
  // Instantiate emulator and path to Cadence files
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../cadence');
    const port = 7002;
    await init(basePath, { port });
    return emulator.start(port, false);
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  it('shall deploy AvatarArtNFT contract', async () => {
    await deployAvatarArtNFT();
  });

  it('supply shall be 0 after contract is deployed', async () => {
    // Setup
    await deployAvatarArtNFT();
    const BnuAdmin = await getAdminAddress();
    await shallPass(setupAvatarArtNFTOnAccount(BnuAdmin));

    await shallResolve(async () => {
      const [supply] = await getAvatarArtNFTSupply();
      expect(supply).toBe(0);
    });
  });

  it('shall be able to mint a avatar art nft', async () => {
    // Setup
    await deployAvatarArtNFT();
    const Alice = await getAccountAddress('Alice');
    await setupAvatarArtNFTOnAccount(Alice);

    // Mint instruction for Alice account shall be resolved
    await shallPass(mintAvatarArtNFT(metadata, Alice));
  });

  it('shall be able to create a new empty NFT Collection', async () => {
    // Setup
    await deployAvatarArtNFT();
    const Alice = await getAccountAddress('Alice');
    await setupAvatarArtNFTOnAccount(Alice);

    // shall be able te read Alice collection and ensure it's empty
    await shallResolve(async () => {
      const [itemCount] = await getAvatarArtCount(Alice);
      expect(itemCount).toBe(0);
    });
  });

  it("shall not be able to withdraw an NFT that doesn't exist in a collection", async () => {
    // Setup
    await deployAvatarArtNFT();
    const Alice = await getAccountAddress('Alice');
    const Bob = await getAccountAddress('Bob');
    await setupAvatarArtNFTOnAccount(Alice);
    await setupAvatarArtNFTOnAccount(Bob);

    // Transfer transaction shall fail for non-existent item
    await shallRevert(transferAvatarArtNFT(Alice, Bob, 1337));
  });

  it('shall be able to withdraw an NFT and deposit to another accounts collection', async () => {
    const adminAddr = await getAdminAddress();
    await deployAvatarArtNFT();
    const Alice = await getAccountAddress('Alice');
    const Bob = await getAccountAddress('Bob');
    await setupAvatarArtNFTOnAccount(Alice);
    await setupAvatarArtNFTOnAccount(Bob);

    // Mint instruction for Alice account shall be resolved
    const [txMint] = await shallPass(mintAvatarArtNFT(metadata, Alice));
    const tokenId = txMint.events.find(
      ({ type }) => type == `A.${sansPrefix(adminAddr)}.AvatarArtNFT.Minted`
    ).data.tokenId;

    // Transfer transaction shall pass
    const [tx, err] = await transferAvatarArtNFT(Alice, Bob, tokenId);
    if (err) {
      throw new Error(err);
    }
    await shallPass([tx]);
  });
});
