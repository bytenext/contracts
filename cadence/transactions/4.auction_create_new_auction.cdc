import FungibleToken from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtTransactionInfo from 0x02
import BNU from 0x01
import AvatarArtAuction from 0x04

transaction (tokenId: UInt64, startTime: UFix64, endTime: UFix64, price: UFix64, owner: Address){
    let nftCollectionRef: &AvatarArtNFT.Collection;
    let auctionRef: &AvatarArtAuction.Auction;

    prepare(adminAccount: AuthAccount) {
        self.nftCollectionRef = adminAccount
                    .borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
                    ?? panic("Can not borrow NFT collection capability");

        self.auctionRef = adminAccount
                    .borrow<&AvatarArtAuction.Auction>(from: AvatarArtAuction.AuctionAdminStoragePath)
                    ?? panic("Can not borrow Auction capability");
    }

    execute {
        let nft <- self.nftCollectionRef.withdraw(withdrawID: tokenId);

        let ownerAccount = getAccount(owner);
        let ownerNftReceiver = ownerAccount
            .getCapability<&{NonFungibleToken.Receiver}>(AvatarArtNFT.CollectionPublicPath)!

        let ownerVaultReceiver = ownerAccount
            .getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);

        self.auctionRef.createNewAuction(
          startTime: startTime,
          endTime: endTime,
          price: price,
          paymentType: BNU.Vault.getType(),
          ownerNftReceiver: ownerNftReceiver,
          ownerVaultReceiver: ownerVaultReceiver,
          nft: <- nft)

        log("New auction created");
    }
}