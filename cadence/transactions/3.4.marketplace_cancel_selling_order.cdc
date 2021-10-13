import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtMarketplace from 0x03

transaction (tokenId: UInt64) {
    let saleCollectionReference: &AvatarArtMarketplace.SaleCollection;
    let userNftReceiver: &{NonFungibleToken.Receiver};

    prepare(account: AuthAccount) {
        self.saleCollectionReference = account
            .borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.CollectionStoragePath)
            ?? panic("Can not borrow AvatarArtMarketplace.SaleCollection");

        self.userNftReceiver = account
            .borrow<&{NonFungibleToken.Receiver}>(from: AvatarArtNFT.CollectionStoragePath)
                ?? panic("Can not borrow NonFungibleToken.Receiver");
    }

    execute {
        let nft <- self.saleCollectionReference.cancelSellingOrder(tokenId: tokenId) as! @NonFungibleToken.NFT;
        self.userNftReceiver.deposit(token: <- nft);

        log("Selling order has been canceled")
    }
}