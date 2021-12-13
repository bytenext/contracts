import AvatarArtAuction from "../../contracts/AvatarArtAuction.cdc";

transaction(auctionID: UInt64) {

  prepare(signer: AuthAccount) {
    let store = signer.borrow<&AvatarArtAuction.AuctionStore{AvatarArtAuction.AuctionStoreManager}>(from: AvatarArtAuction.AuctionStoreStoragePath)
            ?? panic("Please setup store first");
    store.cancelAuction(auctionID: auctionID);
  }
}