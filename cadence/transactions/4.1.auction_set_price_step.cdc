import AvatarArtAuction from 0x04

transaction (price: UFix64, priceStep: UFix64){
    prepare(adminAccount: AuthAccount) {
        let auctionRef = adminAccount
                    .borrow<&AvatarArtAuction.Auction>(from: AvatarArtAuction.AuctionAdminStoragePath)
                    ?? panic("Can not borrow Auction capability");

        auctionRef.setPriceStep(price: price, priceStep: priceStep);
    }
}