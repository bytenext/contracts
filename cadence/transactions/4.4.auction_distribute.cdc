import AvatarArtAuction from 0x02

transaction (tokenId: UInt64, transactionInfoAddress: Address){
    let auctionRef: &AvatarArtAuction.Auction;
    let auctionRef: &AvatarArtAuction.Auction;

    prepare(adminAccount: AuthAccount) {
        self.auctionRef = adminAccount
                    .borrow<&AvatarArtAuction.Auction>(from: AvatarArtAuction.AuctionAdminStoragePath)
                    ?? panic("Can not borrow AvatarArtAuction.Auction capability");
    }

    execute {
        self.auctionRef.distribute(tokenId: tokenId, transactionInfoAccount: getAccount(transactionInfoAddress));
        log("NFT is distributed");
    }
}