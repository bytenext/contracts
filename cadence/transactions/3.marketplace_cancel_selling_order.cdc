import FungibleToken from 0x01
import BNU from 0x02
import NonFungibleToken from 0x03
import AvatarArtNFT from 0x04
import AvatarArtMarketplace from 0x05
import AvatarArtTransactionInfo from 0x01

// This transaction allows the Minter account to mint an NFT
// and deposit it into its collection.

transaction (tokenId: UInt64, recipient: Address) {
    let nftCollectionReference: &AvatarArtNFT.Collection;
    let receiverReference: &AnyResource{NonFungibleToken.Receiver};

    prepare(adminAccount: AuthAccount) {
        //Get token price
        self.nftCollectionReference = adminAccount.borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
          ?? panic("Can not borrow a reference to the sale collection capability");

         self.receiverReference = getAccount(recipient).getCapability<&{NonFungibleToken.Receiver}>(AvatarArtNFT.CollectionPublicPath)
                    .borrow()
          ?? panic("Can not borrow a reference to the sale collection capability");
    }

    execute {
        let token <- self.nftCollectionReference.withdraw(withdrawID: tokenId);

        self.receiverReference.deposit(token: <-token);

        log("Token has been withdrawn!")
    }
}