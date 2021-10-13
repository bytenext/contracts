import FungibleToken from 0x01
import BNU from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtMarketplace from 0x03

transaction (tokenId: UInt64) {
    prepare(account: AuthAccount) {
        let saleCollectionRef = account
            .borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath)
            ?? panic("Could not borrow AvatarArtMarketplace.SaleCollection")

        let collectionRef = account
            .borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
            ?? panic("Could not borrow AvatarArtNFT.Collection")

        let nft <- collectionRef.withdraw(withdrawID: tokenId) as! @AvatarArtNFT.NFT;
        saleCollectionRef.createSellingOrder(tokenId: tokenId, nft: <- nft);
    }

    execute {
        log("Selling order is created!");
    }
}