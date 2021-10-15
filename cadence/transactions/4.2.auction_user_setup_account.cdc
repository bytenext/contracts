import FungibleToken from 0x01
import NonFungibleToken from 0x01
import BNU from 0x01
import AvatarArtAuction from 0x04

transaction {
    let userAddress: Address;
    prepare(userAccount: AuthAccount) {
      self.userAddress = userAccount.address;
      if(userAccount.borrow<&AvatarArtAuction.Auction>(from: AvatarArtAuction.AuctionStoragePath) == nil){
          let ownerVaultReceiver = userAccount
              .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
          let ownerNftReceiver = userAccount
              .getCapability<&{NonFungibleToken.Receiver}>(BNU.ReceiverPath);
          let auction <- AvatarArtAuction.createNewAuction(
            ownerVaultReceiver: ownerVaultReceiver,
            ownerNftReceiver: ownerNftReceiver);

          userAccount.save<@AvatarArtAuction.Auction>(<- auction, to: AvatarArtAuction.AuctionStoragePath)
          userAccount
            .link<&AvatarArtAuction.Auction{AvatarArtAuction.AuctionPublic, AvatarArtAuction.AuctionNFTReceiver}>(
              AvatarArtAuction.AuctionPublicPath, target: AvatarArtAuction.AuctionStoragePath)
      }
        log("Setup done");
    }

    post{
        getAccount(self.userAddress)
          .getCapability<&{AvatarArtAuction.AuctionPublic}>(AvatarArtAuction.AuctionPublicPath)
                .check(): "Can not create capability"
    }
}