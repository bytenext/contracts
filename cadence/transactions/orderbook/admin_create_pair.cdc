import ByteNextOrderBook from "../../contracts/ByteNextOrderBook.cdc"
import BNU from "../../contracts/BNU.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"

transaction(minPrice: UFix64, maxPrice: UFix64, feePercent: UInt64) {
  prepare(signer: AuthAccount) {
    let admin = signer.borrow<&ByteNextOrderBook.Administrator>(from: ByteNextOrderBook.AdminStoragePath)
          ?? panic("Could not borrow admin from address");

    let flowReceiver = signer.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver);
    let bnuReceiver = signer.getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath);

    // Create pair FLow -> BNU: Use Flow to Buy BNU, sell BNU to receive Flow
    admin.createPair(isFrozen: false, minPrice: minPrice, maxPrice: maxPrice,
          paymentVault: <- FlowToken.createEmptyVault(), sellingVault: <- BNU.createEmptyVault(),
          paymentFeeReceiver: flowReceiver, sellingFeeReceiver: bnuReceiver,
          feePercent: feePercent)
  }
}