import { emulator, getAccountAddress, init, shallPass } from 'flow-js-testing';
import path from 'path';
import { setupCurreniesAllow } from '../src/auction';
import {
  metadata,
  mintAvatarArtNFT,
  setupAvatarArtNFTOnAccount
} from '../src/avatar-art-nft';
import {
  deployBnu,
  getBnuBalance,
  mintBnu,
  setupBnuOnAccount
} from '../src/bnu';
import {
  deployMarketplace,
  listForSale,
  purchase,
  setupSaleCollectionForAccount,
  unlistSale
} from '../src/market-place';
import { deployFUSD, deployTransactionInfo } from '../src/transaction-info';
import { toUFix64, tx } from '../src/util';

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(500000);

describe('Avatar Art Marketplace', () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../cadence');
    const port = 7003;
    await init(basePath, { port });
    return emulator.start(port, false);
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  it('shall deploy Avatar Art Marketplace contract', async () => {
    await shallPass(tx(deployMarketplace()));
  });

  it('shall will be create empty sale collection', async () => {
    await deployMarketplace();
    const seller = await getAccountAddress('seller');
    await shallPass(tx(setupSaleCollectionForAccount(seller)));
  });

  it('shall will be not accept to list an nft for a payment not allow', async () => {
    await deployMarketplace();
    await deployBnu();
    const seller = await getAccountAddress('seller');

    await shallPass(tx(setupSaleCollectionForAccount(seller)));
    await setupAvatarArtNFTOnAccount(seller);

    let nftID = 1000;
    let price = 1000;
    await mintAvatarArtNFT(metadata, seller);

    const [, error] = await listForSale(seller, nftID, price);
    expect(error).toContain('Payment type is not allow');
  });

  it('shall will accept to list and unlist an nft for a payment type valid', async () => {
    await deployMarketplace();
    await deployBnu();
    await deployFUSD();
    await deployTransactionInfo();
    const seller = await getAccountAddress('seller');

    await shallPass(tx(setupCurreniesAllow()));
    await shallPass(tx(setupAvatarArtNFTOnAccount(seller)));
    await shallPass(tx(setupSaleCollectionForAccount(seller)));
    await shallPass(tx(setupBnuOnAccount(seller)));

    let nftID = 1000;
    let price = 1000;
    await mintAvatarArtNFT(metadata, seller);

    await shallPass(tx(listForSale(seller, nftID, price)));

    await shallPass(tx(unlistSale(seller, nftID)));
  });

  it('shall will able to buy an nft which on sale', async () => {
    await deployMarketplace();
    await deployBnu();
    await deployFUSD();
    await deployTransactionInfo();
    const seller = await getAccountAddress('seller');
    const buyer = await getAccountAddress('buyer');

    await shallPass(tx(setupCurreniesAllow()));
    await shallPass(tx(setupAvatarArtNFTOnAccount(seller)));
    await shallPass(tx(setupSaleCollectionForAccount(seller)));
    await shallPass(tx(setupBnuOnAccount(seller)));

    await shallPass(tx(setupBnuOnAccount(buyer)));
    await shallPass(tx(mintBnu(buyer, 2000)));

    let nftID = 1000;
    let price = 1000;
    await mintAvatarArtNFT(metadata, seller);
    await shallPass(tx(listForSale(seller, nftID, price)));
    await shallPass(tx(purchase(buyer, seller, nftID, price)));

    const [buyerBalance] = await getBnuBalance(buyer);
    expect(buyerBalance).toBe(toUFix64(2000 - price));

    const [sellerBalance] = await getBnuBalance(buyer);
    expect(+sellerBalance).toBeGreaterThan(0);
  });
});
