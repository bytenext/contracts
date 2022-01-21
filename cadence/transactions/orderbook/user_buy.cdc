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


    // For pair BNU -> FUSD: Use FUSD to buy BNU
    let fusdVaultRef = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
      ?? panic("Could not borrow reference to the owner's Vault!")
    
    let bnuReceiver = signer.getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath);

    if let returnVault <- proxy.buy(pairId: pairId, vault: <- fusdVaultRef.withdraw(amount: requestQty * price), price: price, receiver: bnuReceiver) {
      fusdVaultRef.deposit(from: <- returnVault)
    }
  }
}