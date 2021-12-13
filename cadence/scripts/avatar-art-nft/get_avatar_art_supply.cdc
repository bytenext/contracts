import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc"

// This scripts returns the number of AvatarArtNFT currently in existence.

pub fun main(): UInt64 {    
    return AvatarArtNFT.totalSupply
}