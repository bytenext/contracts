import { emulator, getAccountAddress, getFlowBalance, init, mintFlow, shallPass, shallRevert } from "flow-js-testing";
import path from "path";
import { buyTickets, buyWhitelist, countTickets, createCandidate, deployTicket, deployTickets, getBought, getCandidateFund, getTicketCounts, getTicketPrice, hasBought, mintTicket, setMaxTickets, setSaleCuts, setupTicketOnAccount, setWhitelist, swapTicketForNFT, transferTicket, whitelisted } from "../src/ticket";
import { getAdminAddress, toUFix64, tx } from "../src/util";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(500000);

describe("Tickets", () => {
  // Instantiate emulator and path to Cadence files
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../cadence");
    const port = 7001;
    await init(basePath, { port });
    emulator.setLogging(true);
    return emulator.start(port, false);
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  it("shall have initialized field correctly", async () => {
    // Deploy contract
    await shallPass(tx(deployTicket()));
  });

  it("shall have increase counts correctly", async () => {
    // Deploy contract
    await shallPass(tx(deployTicket()));

    const me = await getAccountAddress('me');
    const you = await getAccountAddress('you');
    await setupTicketOnAccount(me);
    await setupTicketOnAccount(you);

    await shallPass(tx(mintTicket(0, me)));
    await shallPass(tx(mintTicket(0, me)));
    await shallPass(tx(mintTicket(1, me)));
    await shallPass(tx(mintTicket(0, me)));

    const [count, err] = await getTicketCounts(me);

    if (err) {
      throw err
    }

    expect(err).toBe(null);
    expect(count.one).toBe(3);
    expect(count.two).toBe(1);
    expect(count.three).toBe(0);


    const [, e] = await transferTicket(me, you, 1);
    if (e) {
      throw e;
    }
    
    // const [count2,] = await getTicketCounts(me);
    // const [county,] = await getTicketCounts(you);
    // console.log(county)

    // expect(count2.one).toBe(2);
    // expect(county.one).toBe(1);
  });

  it("shall have descrease counts correctly", async () => {
    // Deploy contract
    await shallPass(tx(deployTicket()));

    const me = await getAccountAddress("me");
    const you = await getAccountAddress("you");
    await setupTicketOnAccount(me);
    await setupTicketOnAccount(you);

    await shallPass(tx(mintTicket(0, me)));
    await shallPass(tx(mintTicket(0, me)));

    const [count, err] = await getTicketCounts(me);

    if (err) {
      throw err;
    }

    expect(err).toBe(null);
    expect(count.one).toBe(2);


    const [, e] = await transferTicket(me, you, 1);
    if (e) {
      throw e;
    }

    const [count2,] = await getTicketCounts(me);
    const [county,] = await getTicketCounts(you);

    expect(count2.one).toBe(1);
    expect(county.one).toBe(1);
  });

  it("shall have initial fields Tickets correctly", async () => {
    await shallPass(tx(deployTickets()));
  })

  it("Shall can set whitelist", async () => {
    const admin = await getAdminAddress()
    await shallPass(tx(deployTickets()));

    const you = await getAccountAddress('you')

    expect(await whitelisted(you)).toBe(false);
    await shallPass(tx(setWhitelist(admin, [you])));
    expect(await whitelisted(you)).toBe(true);
  })
  
  it("Shall buy whitelist correctly", async () => {
    const admin = await getAdminAddress();
    await shallPass(tx(deployTickets()));

    const cuts = [];
    for (const i of [...Array(20).keys()]) {
      cuts.push(await getAccountAddress(`cut-${i}`));
    }
    const cutRate = 0.045;
    const rates = [...Array(20).keys()].map(() => cutRate);
    await setSaleCuts(admin, cuts, rates);

    const [price] = await getTicketPrice(0);

    const you = await getAccountAddress("you");
    await mintFlow(you, 1000);
    await shallPass(tx(setWhitelist(admin, [you])));

    let amount = price * 0.6;
    await shallPass(tx(buyWhitelist(you, amount)));

    const [bought] = await hasBought(you);
    expect(bought).toBe(true);

    await shallRevert(buyWhitelist(you, price));

    const [{ one }] = await getBought();
    expect(one).toBe(1);

    const [tickets] = await countTickets(you);
    expect(tickets.one).toBe(1);

    // Check balance
    const [candidateFund] = await getCandidateFund();
    const [cut1] = await getFlowBalance(await getAccountAddress("cut-1"));
    expect(candidateFund).toBe(toUFix64(amount * (1 - 20 * cutRate)));

    expect(cut1).toBe(toUFix64(amount * cutRate + 0.001));
  });


  it("Shall buy normal correctly", async () => {
    const admin = await getAdminAddress();
    await shallPass(tx(deployTickets()));

    const cuts = [];
    for (const i of [...Array(20).keys()]) {
      cuts.push(await getAccountAddress(`cut-${i}`));
    }
    const cutRate = 0.045;
    const rates = [...Array(20).keys()].map(() => cutRate);
    await setSaleCuts(admin, cuts, rates);

    const [price0] = await getTicketPrice(0);
    const [price1] = await getTicketPrice(1);
    const [price2] = await getTicketPrice(2);

    const you = await getAccountAddress("you");
    await mintFlow(you, 1000);

    let qty = 10;
    let amount = qty * price0
    let amount2 = qty * price1
    await shallPass(tx(buyTickets(you, 0, price0, qty)));
    await shallPass(tx(buyTickets(you, 1, price1, qty)));

    // Should not able to buy type = 2
    await shallRevert(buyTickets(you, 2, price2, qty));

    const [{ one, two }] = await getBought();
    expect(one).toBe(10);
    expect(two).toBe(10);

    const [tickets] = await countTickets(you);
    expect(tickets.one).toBe(10);
    expect(tickets.two).toBe(10);

    // Check balance
    const [candidateFund] = await getCandidateFund();
    const [cut1] = await getFlowBalance(await getAccountAddress("cut-1"));
    expect(candidateFund).toBe(
      toUFix64((amount + amount2) * (1 - 20 * cutRate))
    );

    expect(cut1).toBe(toUFix64((amount + amount2) * cutRate + 0.001));
  });



  it("Check exceed tickets", async () => {
    const admin = await getAdminAddress();
    await shallPass(tx(deployTickets()));

    const cuts = [];
    for (const i of [...Array(20).keys()]) {
      cuts.push(await getAccountAddress(`cut-${i}`));
    }
    const cutRate = 0.045;
    const rates = [...Array(20).keys()].map(() => cutRate);
    await setSaleCuts(admin, cuts, rates);
    await setMaxTickets(admin, 1, 6)

    const [price1] = await getTicketPrice(1);

    const you = await getAccountAddress("you");
    await mintFlow(you, 1000000);

    let qty = 5;
    await shallPass(tx(buyTickets(you, 1, price1, qty)));

    let [{ two }] = await getBought();
    expect(two).toBe(qty);

    const [, e] = await buyTickets(you, 1, price1, 2)
    expect(e).not.toBeNull()
    expect(e).toContain('Sold out ticket for this level');

    [{ two }] = await getBought();
    expect(two).toBe(qty);

    const [tickets] = await countTickets(you);
    expect(tickets.two).toBe(qty);
  });


  it("Check swap ticket for NFT", async () => {
    const admin = await getAdminAddress();
    await shallPass(tx(deployTickets()));

    const cuts = [];
    for (const i of [...Array(20).keys()]) {
      cuts.push(await getAccountAddress(`cut-${i}`));
    }
    const cutRate = 0.045;
    const rates = [...Array(20).keys()].map(() => cutRate);
    await setSaleCuts(admin, cuts, rates);
    await createCandidate(admin, 1, "001");

    const [price1] = await getTicketPrice(1);

    const you = await getAccountAddress("you");
    await mintFlow(you, 1000000);

    let qty = 5;
    await shallPass(tx(buyTickets(you, 1, price1, qty)));

    let [{ two }] = await getTicketCounts(you);
    expect(two).toBe(qty);

    await shallPass(tx(swapTicketForNFT(you, 1, 1)));
    await shallRevert(tx(swapTicketForNFT(you, 100, 1)));

    [{ two }] = await getTicketCounts(you);
    expect(two).toBe(qty - 1);

    [{ two }] = await getBought();
    expect(two).toBe(qty);

    // Check exceed
    let i = 0
    for (i = 0; i < 3; i++) {
      await shallPass(tx(swapTicketForNFT(you, i + 2, 1)));
    }


    const [, e] = await swapTicketForNFT(you, 5, 1);
    expect(e).not.toBeNull()
    console.log(e)
  });


});
