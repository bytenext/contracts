import AvatarArtAuction from "../../contracts/AvatarArtAuction.cdc";

transaction() {
  prepare(signer: AuthAccount) {
    if signer.borrow<&AvatarArtAuction.AuctionStore>(from: AvatarArtAuction.AuctionStoreStoragePath) == nil {
      let store <- AvatarArtAuction.createAuctionStore();

      signer.save(<- store, to: AvatarArtAuction.AuctionStoreStoragePath);
      signer.link<&AvatarArtAuction.AuctionStore{AvatarArtAuction.AuctionStorePublic}>(
        AvatarArtAuction.AuctionStorePublicPath,
        target: AvatarArtAuction.AuctionStoreStoragePath
      )
    }
  }
}
 