import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc"

// This transaction configures an account to hold Kitty Items.

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- AvatarArtNFT.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: AvatarArtNFT.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&AvatarArtNFT.Collection{NonFungibleToken.CollectionPublic, AvatarArtNFT.CollectionPublic}>(AvatarArtNFT.CollectionPublicPath, target: AvatarArtNFT.CollectionStoragePath)
        }
    }
}