

import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc";
pub fun main(pairId: String, price: UFix64, qty: UFix64): [ByteNextOrderBook.Order]? {
  if let pair = ByteNextOrderBook.borrowPair(pairId: pairId) {
    return pair.getOpenBuyOrdersForPrice(price: price, qty: qty)
  }

  return nil
}
