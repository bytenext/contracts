import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc"

// This script returns the size of an account's AvatarArtNFT collection.

pub fun main(address: Address): Int {
    let account = getAccount(address)

    let collectionRef = account.getCapability(AvatarArtNFT.CollectionPublicPath)!
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs().length
}