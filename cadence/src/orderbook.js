import {
  deployContractByName,
  executeScript,
  sendTransaction
} from "flow-js-testing";
import { getAdminAddress } from "./util";

export const deployOrderbook = async () => {
  const addr = await getAdminAddress();

  return deployContractByName({
    to: addr,
    name: "ByteNextOrderBook"
  });
};

export const setupOrderbookProxyForAccount = async (account) => {
  const name = "orderbook/user_setup";
  const signers = [account];

  return sendTransaction({ name, signers });
};

export const adminCreatePair = async (minprice, maxPrice, feePercent) => {
  const name = "orderbook/admin_create_pair";

  const account = await getAdminAddress();
  const signers = [account];
  const args = [minprice, maxPrice, feePercent];

  return sendTransaction({ name, signers, args });
};

export const buy = async (account, pairId, price, requestQty) => {
  const name = "orderbook/user_buy";

  const signers = [account];
  const args = [pairId, price, requestQty];

  return sendTransaction({ name, signers, args });
};

export const sell = async (account, pairId, price, requestQty) => {
  const name = "orderbook/user_sell";

  const signers = [account];
  const args = [pairId, price, requestQty];

  return sendTransaction({ name, signers, args });
};

export const cancelOrder = async (account, pairId, orderId, type) => {
  const name = "orderbook/user_cancel";

  const signers = [account];
  const args = [pairId, orderId, type];

  return sendTransaction({ name, signers, args });
};

export const trySecurity = async (account, pairId) => {
  const name = "orderbook/try_security";

  const signers = [account];
  const args = [pairId];

  return sendTransaction({ name, signers, args });
};

export const getDetails = async (pairId) => {
  const name = "orderbook/getDetails";
  const args = [pairId];

  return executeScript({ name, args });
};

export const getOrder = async (pairId, orderId, type) => {
  const name = "orderbook/getOrder";
  const args = [pairId, orderId, type];

  return executeScript({ name, args }).then(([o]) => o);
};

export const getSortedSellOrders = async (pairId, map = true) => {
  const name = "orderbook/getSellOrders";
  const args = [pairId];

  const [orders] = await executeScript({ name, args });

  if (map && orders?.length) {
    return Promise.all(orders.map((o) => getOrder(pairId, o, 1)));
  }

  return orders || [];
};

export const getSortedBuyOrders = async (pairId, map = true) => {
  const name = "orderbook/getBuyOrders";
  const args = [pairId];

  const [orders] = await executeScript({ name, args });

  if (map && orders?.length) {
    return Promise.all(orders?.map((o) => getOrder(pairId, o, 0)));
  }

  return orders || [];
};

export const getMatchForBuyOrder = async (pairId, price, qty) => {
  const name = "orderbook/getMatchForBuyOrder";
  const args = [pairId, price, qty];

  return executeScript({ name, args });
};

export const getMatchForSellOrder = async (pairId, price, qty) => {
  const name = "orderbook/getMatchForSellOrder";
  const args = [pairId, price, qty];

  return executeScript({ name, args });
};
