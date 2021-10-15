import AvatarArtMarketplace from 0x03

transaction (tokenId: UInt64){
    let marketCollectionRef: &AvatarArtMarketplace.SaleCollection;

    prepare(userAccount: AuthAccount) {
        self.marketCollectionRef = userAccount
                    .borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath)
                    ?? panic("Can not borrow AvatarArtMarketplace.SaleCollection capability");
    }

    execute {
        self.marketCollectionRef.cancelSellingOrder(tokenId: tokenId)

        log("Selling order canceled");
    }
}