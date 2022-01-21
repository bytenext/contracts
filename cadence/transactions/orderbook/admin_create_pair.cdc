import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc"
import BNU from "../../contracts/BNU.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"

transaction(minPrice: UFix64, maxPrice: UFix64, feePercent: UInt64) {
  prepare(signer: AuthAccount) {
    let admin = signer.borrow<&ByteNextOrderBook.Administrator>(from: ByteNextOrderBook.AdminStoragePath)
          ?? panic("Could not borrow admin from address");

    let fusdReceiver = signer.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver);
    let bnuReceiver = signer.getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath);

    // Create pair BNU -> FUSD: Use FUSD to Buy BNU, sell BNU to receive BNU
    admin.createPair(id: "BNU_FUSD", isFrozen: false, minPrice: minPrice, maxPrice: maxPrice,
          token0Vault: <- BNU.createEmptyVault(), token1Vault: <- FUSD.createEmptyVault(),
          token0FeeReceiver: bnuReceiver, token1FeeReceiver: fusdReceiver, 
          feePercent: feePercent)
  }
}