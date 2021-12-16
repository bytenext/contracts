import AvatarArtMarketplace from "../../contracts/AvatarArtMarketplace.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc";

transaction() {
  prepare(signer: AuthAccount) {
    let collectionPrivatePath = /private/avatarArtNFTCollection
    if !signer.getCapability<&AvatarArtNFT.Collection>(collectionPrivatePath).check() {
      signer.link<&AvatarArtNFT.Collection>(collectionPrivatePath, target: AvatarArtNFT.CollectionStoragePath)
    }

    if signer.borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath) == nil {
      let collection <- AvatarArtMarketplace.createSaleCollection(
        ownerCollection: signer.getCapability<&AvatarArtNFT.Collection>(collectionPrivatePath)
      )

      signer.save(<-collection, to: AvatarArtMarketplace.SaleCollectionStoragePath)
      signer.link<&AvatarArtMarketplace.SaleCollection{AvatarArtMarketplace.SalePublic}>(AvatarArtMarketplace.SaleCollectionPublicPath, target: AvatarArtMarketplace.SaleCollectionStoragePath)
    }
  }
}