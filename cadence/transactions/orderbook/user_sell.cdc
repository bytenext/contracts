import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc"
import BNU from "../../contracts/BNU.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction(pairId: UInt64, price: UFix64, requestQty: UInt64) {
  prepare(signer: AuthAccount) {

    // Setup Proxy
    if signer.borrow<&ByteNextOrderBook.ExchangeProxy>(from: ByteNextOrderBook.ProxyStoragePath) == nil {
      let proxy <- ByteNextOrderBook.createProxy()
      signer.save(<-proxy, to: ByteNextOrderBook.ProxyStoragePath)
    }

    // TODO: Setup Flow token

    let proxy = signer.borrow<&ByteNextOrderBook.ExchangeProxy>(from: ByteNextOrderBook.ProxyStoragePath)!

    // For pair Flow -> BNU: Use Flow to buy BNU
    let bnuVaultRef = signer.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
      ?? panic("Could not borrow reference to the owner's Vault!")
    
    let flowReceiver = signer.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver);

    proxy.sell(pairId: pairId, vault: <- bnuVaultRef.withdraw(amount: price * UFix64(requestQty)), price: price, requestQty: requestQty, receiver: flowReceiver)
  }
}