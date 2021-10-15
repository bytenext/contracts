import AvatarArtMarketplace from 0x03
import AvatarArtNFT from 0x01

transaction (tokenId: UInt64){
    let marketCollectionRef: &AvatarArtMarketplace.SaleCollection;
    let nftReceiver: &AvatarArtNFT.Collection;


    prepare(userAccount: AuthAccount) {
        self.marketCollectionRef = userAccount
                    .borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath)
                    ?? panic("Can not borrow AvatarArtMarketplace.SaleCollection capability");

        self.nftReceiver = userAccount
                    .borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
                    ?? panic("Can not borrow Auction capability");
    }

    execute {
        self.nftReceiver.deposit(token: <- self.marketCollectionRef.withdrawNft(tokenId: tokenId));

        log("NFT is withdrawn");
    }
}