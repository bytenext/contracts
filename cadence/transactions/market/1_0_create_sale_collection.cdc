import AvatarArtMarketplace from "../../contracts/AvatarArtMarketplace.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc";

transaction() {
  prepare(signer: AuthAccount) {

    if signer.borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath) == nil {
      let collection <- AvatarArtMarketplace.createSaleCollection()

      signer.save(<-collection, to: AvatarArtMarketplace.SaleCollectionStoragePath)
      signer.link<&AvatarArtMarketplace.SaleCollection{AvatarArtMarketplace.SalePublic}>(AvatarArtMarketplace.SaleCollectionPublicPath, target: AvatarArtMarketplace.SaleCollectionStoragePath)
    }
  }
}