import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc"

pub struct AccountItem {
  pub let itemID: UInt64
  pub let metadata: String
  pub let resourceID: UInt64
  pub let owner: Address

  init(itemID: UInt64, metadata: String, resourceID: UInt64, owner: Address) {
    self.itemID = itemID
    self.metadata = metadata
    self.resourceID = resourceID
    self.owner = owner
  }
}

pub fun main(address: Address, itemID: UInt64): AccountItem? {
  if let collection = getAccount(address).getCapability<&AvatarArtNFT.Collection{NonFungibleToken.CollectionPublic, AvatarArtNFT.CollectionPublic}>(AvatarArtNFT.CollectionPublicPath).borrow() {
    if let item = collection.borrowAvatarArtNFT(id: itemID) {
      return AccountItem(itemID: itemID, metadata: item.metadata, resourceID: item.uuid, owner: address)
    }
  }

  return nil
}