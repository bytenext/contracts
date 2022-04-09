
import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc";

pub fun main(pairId: String): [UInt64]? {
  if let pair = ByteNextOrderBook.borrowPair(pairId: pairId) {
    return pair.getSortedBuyOrders()
  }

  return nil
}