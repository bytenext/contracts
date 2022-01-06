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

    // Setup BNU
    if signer.borrow<&BNU.Vault>(from: BNU.StorageVaultPath) == nil {
        // Create a new BNU Vault and put it in storage
        signer.save(<-BNU.createEmptyVault(), to: BNU.StorageVaultPath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&BNU.Vault{FungibleToken.Receiver}>(
            BNU.ReceiverPath,
            target: BNU.StorageVaultPath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&BNU.Vault{FungibleToken.Balance}>(
            BNU.BalancePublicPath,
            target: BNU.StorageVaultPath
        )
    }

    let proxy = signer.borrow<&ByteNextOrderBook.ExchangeProxy>(from: ByteNextOrderBook.ProxyStoragePath)!


    // For pair Flow -> BNU: Use Flow to buy BNU
    let flowVaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("Could not borrow reference to the owner's Vault!")
    
    let bnuReceiver = signer.getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath);

    proxy.buy(pairId: pairId, vault: <- flowVaultRef.withdraw(amount: UFix64(requestQty) * price), price: price, requestQty: requestQty, receiver: bnuReceiver)
  }
}