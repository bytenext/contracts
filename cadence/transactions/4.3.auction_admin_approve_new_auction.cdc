import BNU from 0x01
import AvatarArtAuction from 0x04

transaction (tokenId: UInt64, startPrice: UFix64){
    prepare(adminAccount: AuthAccount) {
        let auctionAdmin = adminAccount
                    .borrow<&AvatarArtAuction.Administrator>(from: AvatarArtAuction.AdminStoragePath)
                    ?? panic("Can not borrow Auction capability");

          auctionAdmin.setNftPrice(tokenId: tokenId, startPrice: startPrice);
          auctionAdmin.setPaymentType(tokenId: tokenId, paymentType: Type<@BNU.Vault>());
    }

    post{
      AvatarArtAuction.nftStartPrices[tokenId] == startPrice:
        "Set start price fail";
    }
}