
import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc";
pub fun main(pairId: String, orderId: UInt64, type: UInt8): ByteNextOrderBook.Order? {
  if let pair = ByteNextOrderBook.borrowPair(pairId: pairId) {
    return pair.getOrder(orderId: orderId, type: ByteNextOrderBook.OrderType(type)!)
  }

  return nil
}