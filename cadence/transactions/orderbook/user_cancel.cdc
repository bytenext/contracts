import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc"
import BNU from "../../contracts/BNU.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction(pairId: String, orderId: UInt64, type: UInt8) {
  prepare(signer: AuthAccount) {
    let orderType = ByteNextOrderBook.OrderType(type)!
    let proxy = signer.borrow<&ByteNextOrderBook.ExchangeProxy>(from: ByteNextOrderBook.ProxyStoragePath)!
    let vault <- proxy.cancel(pairId: pairId, orderId: orderId, type: orderType)

    switch (orderType) {
      case ByteNextOrderBook.OrderType.Sell:
        let bnuReceiver = signer.getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath);
        bnuReceiver.borrow()!.deposit(from: <- vault)
        return;

      case ByteNextOrderBook.OrderType.Buy:
        let fusdReceiver = signer.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver);
        fusdReceiver.borrow()!.deposit(from: <- vault)
        return;
      default:
         panic("OrderType incorrect")
    }

    destroy vault
  }
}