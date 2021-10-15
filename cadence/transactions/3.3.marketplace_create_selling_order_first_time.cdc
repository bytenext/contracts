import FungibleToken from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtMarketplace from 0x03

transaction (tokenId: UInt64){
    let nftCollectionRef: &AvatarArtNFT.Collection;
    let marketCollectionRef: &AvatarArtMarketplace.SaleCollection;

    prepare(userAccount: AuthAccount) {
        self.nftCollectionRef = userAccount
                    .borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
                    ?? panic("Can not borrow NFT collection capability");

        self.marketCollectionRef = userAccount
                    .borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath)
                    ?? panic("Can not borrow AvatarArtMarketplace.SaleCollection capability");
    }

    execute {
        let nft <- self.nftCollectionRef.withdraw(withdrawID: tokenId) as! @AvatarArtNFT.NFT;
        self.marketCollectionRef.createSellingOrder(tokenId: tokenId, nft: <- nft);

        log("New selling order created");
    }
}