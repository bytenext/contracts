import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc"
import BNU from "../../contracts/BNU.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction(pairId: String, price: UFix64, requestQty: UFix64) {
  prepare(signer: AuthAccount) {

    // Setup Proxy
    if signer.borrow<&ByteNextOrderBook.ExchangeProxy>(from: ByteNextOrderBook.ProxyStoragePath) == nil {
      let proxy <- ByteNextOrderBook.createProxy()
      signer.save(<-proxy, to: ByteNextOrderBook.ProxyStoragePath)
    }

    // Setup FUSD
    if signer.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil {
        // Create a new FUSD Vault and put it in storage
        signer.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&FUSD.Vault{FungibleToken.Receiver}>(
            /public/fusdReceiver,
            target: /storage/fusdVault 
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&FUSD.Vault{FungibleToken.Balance}>(
            /public/fusdBalance,
            target: /storage/fusdVault
        )
    }

    let proxy = signer.borrow<&ByteNextOrderBook.ExchangeProxy>(from: ByteNextOrderBook.ProxyStoragePath)!

    // For pair BNU_FUSD: sell BNU to receive FUSD 
    let bnuVaultRef = signer.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
      ?? panic("Could not borrow reference to the owner's Vault!")
    
    let fusdReceiver = signer.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver);
    proxy.sell(pairId: pairId, vault: <- bnuVaultRef.withdraw(amount: requestQty), price: price, receiver: fusdReceiver)
  }
}