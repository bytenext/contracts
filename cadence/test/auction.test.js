import {
  emulator,
  getAccountAddress,
  init,
  shallPass,
  shallRevert
} from 'flow-js-testing';
import path from 'path';
import {
  createAuction,
  deployAuctionStore as deployAuction,
  placeBid,
  settleAuction,
  setupAuctionStoreOnAccount,
  setupCurreniesAllow,
  setupFeePreference
} from '../src/auction';
import {
  getAvatarArt,
  metadata,
  mintAvatarArtNFT,
  setupAvatarArtNFTOnAccount
} from '../src/avatar-art-nft';
import { deployBnu, mintBnu, setupBnuOnAccount } from '../src/bnu';
import { deployFUSD } from '../src/transaction-info';
import { getCurrentTimestamp, sleep, tx } from '../src/util';

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(500000);

describe('Avatar Art Auction', () => {
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

  it('shall deploy AvatarArtAuction contract', async () => {
    await shallPass(deployAuction());
  });

  it('shall be able to create an empty Avatar Art Auction Store', async () => {
    // Setup
    await deployAuction();
    await deployBnu();
    await deployFUSD();

    const Alice = await getAccountAddress('Alice');

    await shallPass(setupAuctionStoreOnAccount(Alice));
    await shallPass(setupFeePreference());

    await shallPass(setupCurreniesAllow());
  });

  it('shall will be create an auction successfully', async () => {
    // Setup
    const seller = await getAccountAddress('seller');
    await prepareAuction(seller);

    // Mint a NFT for seller
    await shallPass(mintAvatarArtNFT(metadata, seller));

    const now = await getCurrentTimestamp();

    const nftID = 1000;
    const startTime = now;
    const endTime = +now + 10;
    const startPrice = 3;

    // Create an auction
    await shallPass(
      tx(createAuction(seller, nftID, startTime, endTime, startPrice))
    );
  });

  it('shall will be create an auction fail with input incorrect', async () => {
    // Setup
    const seller = await getAccountAddress('seller');
    await prepareAuction(seller);

    // Mint a NFT for seller
    await shallPass(mintAvatarArtNFT(metadata, seller));

    const now = await getCurrentTimestamp();

    const nftID = 1000;
    const startTime = now;
    const startPrice = 3;

    // Create an auction with start time > endtime
    await shallRevert();

    const [, e] = await createAuction(
      seller,
      nftID,
      startTime,
      startTime - 1,
      startPrice
    );
    expect(e).not.toBeNull();
    expect(e).toContain('Endtime should be greater than start time');

    // Create an auction with endtime < now
    const [, error] = await createAuction(
      seller,
      nftID,
      startTime - 2,
      startTime - 1,
      startPrice
    );
    expect(error).not.toBeNull();
    expect(error).toContain('End time should be greater than current time');
  });

  it('shall will be place a bid successfully', async () => {
    // Setup
    const seller = await getAccountAddress('seller');
    await prepareAuction(seller);

    const buyer = await getAccountAddress('buyer');
    await setupBnuOnAccount(buyer);
    await mintBnu(buyer, 1000);

    // Mint a NFT for seller
    await shallPass(mintAvatarArtNFT(metadata, seller));

    const now = await getCurrentTimestamp();

    const nftID = 1000;
    const startTime = now;
    const endTime = +now + 10;
    const startPrice = 30;

    // Create an auction
    const [data] = await shallPass(
      tx(createAuction(seller, nftID, startTime, endTime, startPrice))
    );
    const event = data.events.find(({ type }) =>
      type.includes('AvatarArtAuction.AuctionAvailable')
    );
    const auctionID = event.data.auctionID;
    await shallPass(tx(placeBid(buyer, seller, auctionID, startPrice)));
  });

  it('shall will be place a bid fail with buyer not enough BNU', async () => {
    // Setup
    const seller = await getAccountAddress('seller');
    await prepareAuction(seller);

    const buyer = await getAccountAddress('buyer');
    await setupBnuOnAccount(buyer);
    await mintBnu(buyer, 1000);

    // Mint a NFT for seller
    await shallPass(mintAvatarArtNFT(metadata, seller));

    const now = await getCurrentTimestamp();

    const nftID = 1000;
    const startTime = now;
    const endTime = +now + 10;
    const startPrice = 3000;

    // Create an auction
    const [data] = await shallPass(
      tx(createAuction(seller, nftID, startTime, endTime, startPrice))
    );
    const event = data.events.find(({ type }) =>
      type.includes('AvatarArtAuction.AuctionAvailable')
    );
    const auctionID = event.data.auctionID;
    const [, error] = await placeBid(buyer, seller, auctionID, startPrice);
    expect(error).not.toBeNull();
    expect(error).toContain(
      'Amount withdrawn must be less than or equal than the balance of the Vault'
    );
  });

  it('shall will be place a bid fail because invalid time or price', async () => {
    // Setup
    const seller = await getAccountAddress('seller');
    await prepareAuction(seller);

    const buyer = await getAccountAddress('buyer');
    await setupBnuOnAccount(buyer);
    await mintBnu(buyer, 1000);

    // Mint a NFT for seller
    await shallPass(mintAvatarArtNFT(metadata, seller));

    const now = await getCurrentTimestamp();

    const nftID = 1000;
    const startTime = +now + 2;
    const endTime = +now + 5;
    const startPrice = 200;

    // Create an auction
    const [data] = await shallPass(
      tx(createAuction(seller, nftID, startTime, endTime, startPrice))
    );
    const event = data.events.find(({ type }) =>
      type.includes('AvatarArtAuction.AuctionAvailable')
    );
    const auctionID = event.data.auctionID;
    let [, error] = await placeBid(buyer, seller, auctionID, startPrice);
    expect(error).not.toBeNull();
    expect(error).toContain('Invalid time to place');

    // Increase block timestamp in emulator 2 seconds
    await sleep(2000);
    await mintBnu(buyer, 1000);
    await sleep(1000);

    [, error] = await placeBid(buyer, seller, auctionID, startPrice - 20);
    expect(error).not.toBeNull();
    expect(error).toContain(
      'bid amount + (your current bid) must be larger or equal to the current price + minimum bid increment'
    );

    // Increase block timestamp in emulator 4 seconds to end auction
    await sleep(1000);
    await mintBnu(buyer, 1000);

    const now2 = await getCurrentTimestamp();
    if (now2 > endTime) {
      [, error] = await placeBid(buyer, seller, auctionID, startPrice);
      expect(error).not.toBeNull();
      expect(error).toContain('Invalid time to place');
    }
  });

  it('shall will be return nft back to seller when no bids', async () => {
    // Setup
    const seller = await getAccountAddress('seller');
    await prepareAuction(seller);

    // Mint a NFT for seller
    await shallPass(mintAvatarArtNFT(metadata, seller));

    const now = await getCurrentTimestamp();

    const nftID = 1000;
    const startTime = now;
    const endTime = +now + 1;
    const startPrice = 3;

    // Create an auction
    const [data] = await shallPass(
      tx(createAuction(seller, nftID, startTime, endTime, startPrice))
    );
    await sleep(2000);
    await mintBnu(seller, 1000);
    await mintBnu(seller, 1000);

    const now2 = await getCurrentTimestamp();
    if (now2 <= endTime) {
      console.warn('Auction not expired');
      return;
    }

    const event = data.events.find(({ type }) =>
      type.includes('AvatarArtAuction.AuctionAvailable')
    );
    const auctionID = event.data.auctionID;

    await shallPass(tx(settleAuction(seller, auctionID)));

    const nft = await getAvatarArt(seller, nftID);
    expect(nft).not.toBeNull();
  });

  it('shall will be transfer nft to buyer', async () => {
    // Setup
    const seller = await getAccountAddress('seller');
    const buyer = await getAccountAddress('buyer');
    await prepareAuction(seller);

    await setupAvatarArtNFTOnAccount(buyer);
    await setupBnuOnAccount(buyer);
    await mintBnu(buyer, 1000);

    // Mint a NFT for seller
    await shallPass(mintAvatarArtNFT(metadata, seller));

    const now = await getCurrentTimestamp();

    const nftID = 1000;
    const startTime = now;
    const endTime = +now + 2;
    const startPrice = 3;

    // Create an auction
    const [data] = await shallPass(
      tx(createAuction(seller, nftID, startTime, endTime, startPrice))
    );
    const event = data.events.find(({ type }) =>
      type.includes('AvatarArtAuction.AuctionAvailable')
    );
    const auctionID = event.data.auctionID;

    let [, error] = await placeBid(buyer, seller, auctionID, startPrice);
    expect(error).toBeNull();

    await sleep(2000);
    await mintBnu(seller, 1000);
    await sleep(1000);
    await mintBnu(seller, 1000);
    await mintBnu(seller, 1000);
    await mintBnu(seller, 1000);

    const now2 = await getCurrentTimestamp();
    if (now2 <= endTime) {
      console.warn('Auction not expired');
      return;
    }

    await shallPass(tx(settleAuction(seller, auctionID)));

    const nft = await getAvatarArt(buyer, nftID);
    expect(nft).not.toBeNull();
  });

  async function prepareAuction(seller, setup_currency = true) {
    await deployAuction();
    await deployBnu();
    await deployFUSD();
    await shallPass(setupAuctionStoreOnAccount(seller));
    await shallPass(setupFeePreference());

    if (setup_currency) {
      await shallPass(setupCurreniesAllow());
    }
  }
});
