import NonFungibleToken from 0x03
import AvatarArtNFT from 0x04

transaction (recipient: Address) {
    // The reference to the collection that will be receiving the NFT
    let receiverRef: &{AvatarArtNFT.AvatarArtNFTCollectionPublic}

    // The reference to the Minter resource stored in account storage
    let minterReference: &AvatarArtNFT.NFTMinter

    prepare(adminAccount: AuthAccount) {
        // Get the owner's collection capability and borrow a reference
        var recipientAccount = getAccount(recipient);
        self.receiverRef = recipientAccount
            .getCapability<&{AvatarArtNFT.AvatarArtNFTCollectionPublic}>(AvatarArtNFT.CollectionPublicPath)
            .borrow()
            ?? panic("Could not borrow receiver reference")
        
        // Borrow a capability for the NFTMinter in storage
        self.minterReference = adminAccount.borrow<&AvatarArtNFT.NFTMinter>(from: AvatarArtNFT.MinterStoragePath)
            ?? panic("could not borrow minter reference")
    }

    execute {
        // Use the minter reference to mint an NFT, which deposits
        // the NFT into the collection that is sent as a parameter.
        self.minterReference.mintNFT(recipient: self.receiverRef)
        log("NFT minted");
    }
}