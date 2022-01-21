
import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc"

transaction(pairId: String) {
  prepare() {
    if let pair = ByteNextOrderBook.borrowPair(pairId: pairId) {
      pair.getSortedBuyOrders().append(2)
      pair.getSortedSellOrders().append(2)
    }
  }

}