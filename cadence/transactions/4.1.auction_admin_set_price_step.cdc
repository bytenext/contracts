import AvatarArtAuction from 0x04

transaction (prices: [UFix64], priceSteps: [UFix64]){
    prepare(adminAccount: AuthAccount) {
        if(prices.length != priceSteps.length){
          panic("Invalid parameter");
        }
        let auctionAdmin = adminAccount
                    .borrow<&AvatarArtAuction.Administrator>(from: AvatarArtAuction.AdminStoragePath)
                    ?? panic("Can not borrow Auction capability");

        var index = 0;
        for price in prices{
          auctionAdmin.setPriceStep(price: price, priceStep: prices[index]);
          index = index + 1;
        }
    }
}