import FungibleToken from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import BNU from 0x01
import AvatarArtMarketplace from 0x03

transaction (tokenId: UInt64, price: UFix64){
    let marketCollectionRef: &AvatarArtMarketplace.SaleCollection;

    prepare(userAccount: AuthAccount) {
        self.marketCollectionRef = userAccount
                    .borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath)
                    ?? panic("Can not borrow AvatarArtMarketplace.SaleCollection capability");
    }

    execute {
        self.marketCollectionRef.userCreateSellingOrder(
            tokenId: tokenId,
            price: price,
            paymentType: Type<@BNU.Vault>());

        log("New selling order created");
    }
}