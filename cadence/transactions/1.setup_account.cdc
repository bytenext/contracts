
import FungibleToken from 0x01
import BNU from 0x02

import NonFungibleToken from 0x03
import AvatarArtNFT from 0x04

transaction {

    prepare(userAccount: AuthAccount) {
        //Creat BNU vault and store
		let bnuVault <- BNU.createEmptyVault();
		userAccount.save<@BNU.Vault>(<- bnuVault, to: BNU.StorageVaultPath);
        userAccount.link<&BNU.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(BNU.ReceiverPath, target: BNU.StorageVaultPath);

        //Create NFT collection and store
        let collection: @AvatarArtNFT.Collection <- AvatarArtNFT.createEmptyCollection();
        userAccount.save<@AvatarArtNFT.Collection>(<- collection, to: AvatarArtNFT.CollectionStoragePath);
        userAccount.link<&AvatarArtNFT.Collection{NonFungibleToken.CollectionPublic, AvatarArtNFT.AvatarArtNFTCollectionPublic}>(
            AvatarArtNFT.CollectionPublicPath, target: AvatarArtNFT.CollectionStoragePath);
        log("Setup done");
    }

    post{
        getAccount(0x03).getCapability<&{NonFungibleToken.Receiver}>(AvatarArtNFT.ReceiverPublicPath)
                .check(): "Can not create capability"
    }
}