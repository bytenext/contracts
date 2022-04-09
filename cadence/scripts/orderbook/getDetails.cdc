import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc";

pub fun main(pairId: String): ByteNextOrderBook.PairDetails? {
  if let pair = ByteNextOrderBook.borrowPair(pairId: pairId) {
    return pair.getDetails()
  }

  return nil
}