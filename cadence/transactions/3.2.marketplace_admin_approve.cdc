import BNU from 0x01
import AvatarArtMarketplace from 0x03

transaction (tokenId: UInt64, price: UFix64){
    prepare(adminAccount: AuthAccount) {
        let auctionAdmin = adminAccount
                    .borrow<&AvatarArtMarketplace.Administrator>(from: AvatarArtMarketplace.AdministratorStoragePath)
                    ?? panic("Can not borrow Auction capability");

          auctionAdmin.setNftPrice(tokenId: tokenId, price: price);
          auctionAdmin.setPaymentType(tokenId: tokenId, paymentType: Type<@BNU.Vault>());
    }

    post{
      AvatarArtMarketplace.nftPrices[tokenId] == price:
        "Set start price fail";
    }
}