import AvatarArtAuction from "../../contracts/AvatarArtAuction.cdc";
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc";
import BNU from "../../contracts/BNU.cdc";
import FungibleToken from "../../contracts/FungibleToken.cdc";
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc";

transaction(storeAddress: Address, auctionID: UInt64, bidAmount: UFix64) {
  prepare(signer: AuthAccount) {
    let store = getAccount(storeAddress)
        .getCapability<&AvatarArtAuction.AuctionStore{AvatarArtAuction.AuctionStorePublic}>(AvatarArtAuction.AuctionStorePublicPath)
        .borrow()
        ?? panic("Please setup store first");

    let auction = store.borrowAuction(auctionID: auctionID)
        ?? panic("No auction found with given id");

    let collectionCap = signer.getCapability<&AvatarArtNFT.Collection{AvatarArtNFT.CollectionPublic}>(
      AvatarArtNFT.CollectionPublicPath
    );
    if !collectionCap.check() {
      // Setup Collection
      signer.unlink(AvatarArtNFT.CollectionPublicPath)
      destroy <- signer.load<@AnyResource>(from: AvatarArtNFT.CollectionStoragePath)

      // store an empty NFT Collection in account storage
      signer.save(<- AvatarArtNFT.createEmptyCollection(), to: AvatarArtNFT.CollectionStoragePath)

      // publish a capability to the Collection in storage
      signer.link<&AvatarArtNFT.Collection{NonFungibleToken.CollectionPublic, AvatarArtNFT.CollectionPublic}>(
        AvatarArtNFT.CollectionPublicPath,
        target: AvatarArtNFT.CollectionStoragePath
      )
    }

    let vaultCap = signer.getCapability<&BNU.Vault{FungibleToken.Receiver}>(BNU.ReceiverPath);
    assert(vaultCap.check(), message: "The BNU Vault receiver not setup");

    let currentBid = auction.currentBidForUser(address: signer.address);
    let bnuVault = signer.borrow<&BNU.Vault>(from: BNU.StorageVaultPath)
        ?? panic("Missing BNU Vault");
    let bidTokens <- bnuVault.withdraw(amount: bidAmount - currentBid);

    auction.placeBid(
      price: bidAmount,
      affiliateVaultCap: nil,
      vaultCap: vaultCap,
      collectionCap: collectionCap,
      bidTokens: <- bidTokens);
   
  }
}