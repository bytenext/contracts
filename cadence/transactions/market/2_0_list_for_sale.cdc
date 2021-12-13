import FungibleToken from "../../contracts/FungibleToken.cdc"
import AvatarArtMarketplace from "../../contracts/AvatarArtMarketplace.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc";
import BNU from "../../contracts/BNU.cdc";

transaction(nftID: UInt64, price: UFix64) {

    prepare(signer: AuthAccount) {
        // check to see if sale collection already exists
        if signer.borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath) == nil {
            let collection <- AvatarArtMarketplace.createSaleCollection()

            signer.save(<-collection, to: AvatarArtMarketplace.SaleCollectionStoragePath)
            signer.link<&AvatarArtMarketplace.SaleCollection{AvatarArtMarketplace.SalePublic}>(AvatarArtMarketplace.SaleCollectionPublicPath, target: AvatarArtMarketplace.SaleCollectionStoragePath)
        } 

        let ownerCapability = signer.getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        // borrow a reference to the sale
        let saleCollection = signer.borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath)
            ?? panic("Could not borrow from sale in storage")

    
        let nftCollection = signer.borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
            ?? panic("Could not borrow from owner NFT collection")

        let nft <- nftCollection.withdraw(withdrawID: nftID) as! @AvatarArtNFT.NFT
        
        // put the moment up for sale
        saleCollection.listForSale(nft: <- nft, price: price, paymentType: Type<@BNU.Vault>(), receiver: ownerCapability)
        
    }
}