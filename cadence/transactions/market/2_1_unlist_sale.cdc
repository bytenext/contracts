import FungibleToken from "../../contracts/FungibleToken.cdc"
import AvatarArtMarketplace from "../../contracts/AvatarArtMarketplace.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc";

transaction(tokenID: UInt64) {
  prepare(signer: AuthAccount) {
      // borrow a reference to the sale
      let saleCollection = signer.borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath)
          ?? panic("Could not borrow from sale in storage")

      saleCollection.unlistSale(tokenID: tokenID)
  }
}