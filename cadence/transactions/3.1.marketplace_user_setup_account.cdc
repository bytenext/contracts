import FungibleToken from 0x01
import NonFungibleToken from 0x01
import BNU from 0x01
import AvatarArtMarketplace from 0x03

transaction {
    let userAddress: Address;
    prepare(userAccount: AuthAccount) {
      self.userAddress = userAccount.address;
      if(userAccount.borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.SaleCollectionStoragePath) == nil){
          let ownerVaultReceiver = userAccount
              .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
          let ownerNftReceiver = userAccount
              .getCapability<&{NonFungibleToken.Receiver}>(BNU.ReceiverPath);
          let auction <- AvatarArtMarketplace.createMarketplaceCollection(
            ownerTokenReceiver: ownerVaultReceiver);

          userAccount.save<@AvatarArtMarketplace.SaleCollection>(<- auction, to: AvatarArtMarketplace.SaleCollectionStoragePath);
          userAccount
            .link<&AvatarArtMarketplace.SaleCollection{AvatarArtMarketplace.SalePublic, AvatarArtMarketplace.SaleCollectionNftReceiver}>(
              AvatarArtMarketplace.SaleCollectionPublicPath, target: AvatarArtMarketplace.SaleCollectionStoragePath)
      }
        log("Setup done");
    }

    post{
        getAccount(self.userAddress)
          .getCapability<&{AvatarArtMarketplace.SalePublic}>(AvatarArtMarketplace.SaleCollectionPublicPath)
                .check(): "Can not create capability"
    }
}