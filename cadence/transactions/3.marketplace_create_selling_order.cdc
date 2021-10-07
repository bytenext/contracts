import FungibleToken from 0x01
import BNU from 0x02
import NonFungibleToken from 0x03
import AvatarArtNFT from 0x04
import AvatarArtMarketplace from 0x05
import AvatarArtTransactionInfo from 0x01

// This transaction allows the Minter account to mint an NFT
// and deposit it into its collection.

transaction (tokenId: UInt64, price: UFix64, seller: Address) {
    let saleCollectionReference: &AvatarArtMarketplace.SaleCollection;

    prepare(adminAccount: AuthAccount) {
        //Get token price
        self.saleCollectionReference = adminAccount.borrow<&AvatarArtMarketplace.SaleCollection>(from: AvatarArtMarketplace.CollectionStoragePath)
          ?? panic("Can not borrow a reference to the sale collection capability");
    }

    execute {

        self.saleCollectionReference.createSellingOrder(
            tokenId: tokenId,
            price: price,
            owner: seller)

        log("Selling order is created!")
    }
}