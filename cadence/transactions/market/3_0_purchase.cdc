
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import AvatarArtMarketplace from "../../contracts/AvatarArtMarketplace.cdc"
import AvatarArtNFT from "../../contracts/AvatarArtNFT.cdc";
import BNU from "../../contracts/BNU.cdc";

transaction(sellerAddress: Address, tokenID: UInt64, purchaseAmount: UFix64) {
  prepare(signer: AuthAccount) {
        if signer.borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath) == nil {
          let store <- AvatarArtNFT.createEmptyCollection();

          signer.save(<- store, to: AvatarArtNFT.CollectionStoragePath);
        }

        signer.unlink(AvatarArtNFT.CollectionPublicPath)
        signer.link<&AvatarArtNFT.Collection{AvatarArtNFT.CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(
            AvatarArtNFT.CollectionPublicPath,
            target: AvatarArtNFT.CollectionStoragePath
        )

        // borrow a reference to the signer's collection
        let receiver = signer.getCapability<&AvatarArtNFT.Collection{NonFungibleToken.CollectionPublic}>(AvatarArtNFT.CollectionPublicPath)
        
        // borrow a reference to the signer's fungible token Vault
        let provider = signer.borrow<&BNU.Vault{FungibleToken.Provider}>(from: BNU.StorageVaultPath)!
        
        // withdraw tokens from the signer's vault
        let tokens <- provider.withdraw(amount: purchaseAmount)

        // get the seller's public account object
        let seller = getAccount(sellerAddress)

        // borrow a public reference to the seller's sale collection
        let nftCollection = seller.getCapability<&AvatarArtMarketplace.SaleCollection{AvatarArtMarketplace.SalePublic}>(AvatarArtMarketplace.SaleCollectionPublicPath)
            .borrow()
            ?? panic("Could not borrow public sale reference")
    
        // purchase the moment
        nftCollection.purchase(tokenID: tokenID, buyTokens: <-tokens, receiverCap: receiver, affiliateVaultCap: nil)
  }
}