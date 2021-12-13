import FungibleToken from "../../contracts/FungibleToken.cdc"
import AvatarArtMarketplace from "../../contracts/AvatarArtMarketplace.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc";

transaction(tokenID: UInt64) {
  prepare(signer: AuthAccount) {
        // borrow a reference to the sale
        let saleCollection = signer.borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath)
            ?? panic("Could not borrow from sale in storage")
        
        let nftCollection = signer.borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
            ?? panic("Could not borrow from owner NFT collection")

        let nft <- saleCollection.unlistSale(tokenID: tokenID)

        nftCollection.deposit(token: <- nft)
  }
}