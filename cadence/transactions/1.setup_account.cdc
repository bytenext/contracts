
import FungibleToken from 0x01
import BNU from 0x02

import NonFungibleToken from 0x03
import AvatarArtNFT from 0x04

// This transaction allows the Minter account to mint an NFT
// and deposit it into its collection.

transaction {

    prepare(userAccount: AuthAccount) {
        let bnuReceiverPath = /public/bnuReceiver;
        let bnuVaultPath = /storage/bnuVault;
        let avatarArtNFTCollectionPath = /storage/avatarArtNFTCollection;
        let avatarArtNFTReceiverPath: PublicPath = /public/avatarArtNFTReceiver;

        //Creat BNU vault and store
		let bnuVault <- BNU.createEmptyVault();
		userAccount.save<@BNU.Vault>(<- bnuVault, to: bnuVaultPath);
        userAccount.link<&BNU.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(bnuReceiverPath, target: bnuVaultPath);

        //Create NFT collection and store
        //Create NFT collection and store
        let collection: @AvatarArtNFT.Collection <- AvatarArtNFT.createEmptyCollection();
        userAccount.save<@AvatarArtNFT.Collection>(<- collection, to: AvatarArtNFT.CollectionStoragePath);
        userAccount.link<&{NonFungibleToken.Receiver}>(AvatarArtNFT.ReceiverPublicPath, target: AvatarArtNFT.CollectionStoragePath);
        log("Setup done");
    }

    post{
        getAccount(0x03).getCapability<&{NonFungibleToken.Receiver}>(AvatarArtNFT.ReceiverPublicPath)
                .check(): "Can not create capability"
    }
}