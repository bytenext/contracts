import { getAccount } from "@onflow/fcl";
import { executeScript, getAccountAddress, sendTransaction } from "flow-js-testing";
import { deployNested, getAdminAddress } from "./util";

export const deployTicket = async () => {
  const addr = await getAdminAddress();
  await deployNested({ to: addr, path: "core/NonFungibleToken" });

  const addressMap = { NonFungibleToken: addr };
  return deployNested({ to: addr, path: "mu/Ticket", addressMap });
};

export const deployVnMissCandidate = async () => {
  const addr = await getAdminAddress();
  return deployNested({ to: addr, path: "mu/VnMissCandidate" });
};

export const deployVnMetaViews = async () => {
  const addr = await getAdminAddress();
  return deployNested({ to: addr, path: "mu/MetadataViews" });
};

export const deployVnMiss = async () => {
  const addr = await getAdminAddress();
  await deployVnMissCandidate()
  await deployVnMetaViews()

  const addressMap = {
    NonFungibleToken: addr,
    MetadataViews: addr,
    VnMissCandidate: addr
  };
  return deployNested({ to: addr, path: "mu/VnMiss", addressMap });
}

export const deployWhitelist = async () => {
  const addr = await getAdminAddress();
  return deployNested({ to: addr, path: "mu/Whitelist" });
};

export const deployTickets = async () => {
  const addr = await getAdminAddress();
  await deployTicket()
  await deployVnMiss()
  await deployWhitelist()

  return deployNested({
    to: addr,
    path: "mu/Tickets",
    addressMap: {
      Ticket: addr,
      VnMiss: addr,
      Whitelist: addr,
      VnMissCandidate: addr,
      NonFungibleToken: addr
    }
  });
};

export const setupTicketOnAccount = async (account) => {
  const name = 'tickets/setup_account';
  const signers = [account];

  return sendTransaction({ name, signers });
};

export const mintTicket = async (level, recipient) => {
  const AdminAddr = await getAdminAddress();

  const name = 'tickets/mint_ticket';
  const args = [recipient, level];
  const signers = [AdminAddr];

  return sendTransaction({ name, args, signers });
};

export const transferTicket = async (from, recipient, tokenId) => {
  const name = 'tickets/transfer_tickets';
  const args = [recipient, tokenId];
  const signers = [from];

  return sendTransaction({ name, args, signers });
};

export const setWhitelist = async (signer, addresses) => {
  const name = "tickets/admin-set-whitelist";
  const args = [addresses];
  const signers = [signer];

  return sendTransaction({ name, args, signers });
}

export const setMaxTickets = async (signer, level, max) => {
  const name = "tickets/admin-set-max-ticket";
  const args = [level, max];
  const signers = [signer];

  return sendTransaction({ name, args, signers });
}

export const getBought = async  () => {
  const name = 'tickets/get-bought';
  const args = [];

  return executeScript({ name, args });
}

export const whitelisted = async  (address) => {
  const name = 'tickets/get-whitelisted'
  const args = [address];
  return executeScript({ name, args }).then(([w]) => w);
}

export const hasBought = async  (address) => {
  const name = 'tickets/has-bought'
  const args = [address];
  return executeScript({ name, args });
}


export const countTickets = async  (address) => {
  const name = 'tickets/get-counts'
  const args = [address];
  return executeScript({ name, args });
}

export const getMinted = async  (id, level) => {
  const name = 'tickets/get-minted'
  const args = [id, level];
  return executeScript({ name, args });
}

export const getTicketCounts = async (owner) => {
  const name = 'tickets/get-counts';
  const args = [owner];

  return executeScript({ name, args });
}


export const getTicketPrice = async (level) => {
  const name = 'tickets/get-price';
  const args = [level];

  return executeScript({ name, args });
}

export const getCandidateFund = async () => {
  const name = 'tickets/get-candidate-fund';
  const args = [];

  return executeScript({ name, args });
}

export const setSaleCuts = async (signer, recipients, rates) => {
  const name = 'tickets/admin-set-salecut';
  const args = [recipients, rates];
  const signers = [signer];

  return sendTransaction({ name, args, signers });
}

export const buyTickets = async (signer, level, price, qty) => {
  const name = 'tickets/buy';
  const args = [level, price, qty];
  const signers = [signer];

  return sendTransaction({ name, args, signers });
}

export const buyWhitelist = async (signer, price) => {
  const name = 'tickets/buy-discount';
  const args = [price];
  const signers = [signer];

  return sendTransaction({ name, args, signers })
      .then(e => {
        console.log(JSON.stringify(e?.[0].events, null, 2));
        return e
      });
}

export const swapTicketForNFT = async (signer, ticketId, candidateId) => {
  const name = 'tickets/swap-ticket';
  const args = [ticketId, candidateId];
  const signers = [signer];

  return sendTransaction({ name, args, signers });
}

/**
 *   id: UInt64,
    name: String,
    code: String,
    description: String,
    fundAddress: Address,
    properties: {String: String}
 */
export const createCandidate = async (signer, id, code) => {
  const name = 'tickets/admin-create-candidate';
  const addr = await getAccountAddress('fund')
  const args = [id, code, code, 'Description', addr, {}];
  const signers = [signer];

  return sendTransaction({ name, args, signers });
}
 