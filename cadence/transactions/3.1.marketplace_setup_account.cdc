
import BNU from 0x01
import FungibleToken from 0x01
import AvatarArtMarketplace from 0x03

transaction {
    let userAddress: Address;
    prepare(userAccount: AuthAccount) {
        let ownerTokenReceiver = userAccount.getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);

        //Creat BNU vault and store
		let collection <- AvatarArtMarketplace.createSaleCollection(ownerTokenReceiver: ownerTokenReceiver);
		userAccount.save<@AvatarArtMarketplace.SaleCollection>(<- collection, to: AvatarArtMarketplace.CollectionStoragePath);
        userAccount.link<&AvatarArtMarketplace.SaleCollection{AvatarArtMarketplace.SaleCollectionPublic}>(
                AvatarArtMarketplace.CollectionPublicPath, target: AvatarArtMarketplace.CollectionStoragePath);
        
        self.userAddress = userAccount.address;
        log("Setup done");
    }

    post{
        getAccount(self.userAddress).getCapability<&{AvatarArtMarketplace.SaleCollectionPublic}>(AvatarArtMarketplace.CollectionPublicPath)
                .check(): "Can not create capability"
    }
}