import AvatarArtAuction from "../../contracts/AvatarArtAuction.cdc";
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc";
import BNU from "../../contracts/BNU.cdc";
import FungibleToken from "../../contracts/FungibleToken.cdc";

transaction(nftID: UInt64, startTime: UFix64, endTime: UFix64, startPrice: UFix64) {
  prepare(signer: AuthAccount) {
    let store = signer.borrow<&AvatarArtAuction.AuctionStore>(from: AvatarArtAuction.AuctionStoreStoragePath)
            ?? panic("Please setup store first")


    let collectionCap = signer.getCapability<&AvatarArtNFT.Collection{AvatarArtNFT.CollectionPublic}>(
      AvatarArtNFT.CollectionPublicPath
    );
    assert(collectionCap.check(), message: "The AvatarArt Collection receiver not setup")

    let vaultCap = signer.getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath);
    assert(vaultCap.check(), message: "The BNU Vault receiver not setup")

    let collection = signer.borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
        ?? panic("Missing collection resource");

    let nft <- collection.withdraw(withdrawID: nftID) as! @AvatarArtNFT.NFT;

    let id = store.createStandaloneAuction(
      token: <- nft,
      bidVault: <- BNU.createEmptyVault(),
      startTime: startTime,
      endTime: endTime,
      startPrice: startPrice,
      collectionCap: collectionCap,
      vaultCap: vaultCap)

    log("Auction ID ".concat(id.toString()))
  }

}