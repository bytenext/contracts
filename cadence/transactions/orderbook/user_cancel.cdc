import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc"
import BNU from "../../contracts/BNU.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction(pairId: UInt64, orderId: UInt64, type: UInt8) {
  prepare(signer: AuthAccount) {
    let proxy = signer.borrow<&ByteNextOrderBook.ExchangeProxy>(from: ByteNextOrderBook.ProxyStoragePath)!
    proxy.cancel(pairId: pairId, orderId: orderId, type: ByteNextOrderBook.OrderType(type)!)
  }
}