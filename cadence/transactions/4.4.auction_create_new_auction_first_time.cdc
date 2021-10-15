import FungibleToken from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtTransactionInfo from 0x02
import BNU from 0x01
import AvatarArtAuction from 0x04

transaction (tokenId: UInt64, startTime: UFix64, endTime: UFix64){
    let nftCollectionRef: &AvatarArtNFT.Collection;
    let auctionRef: &AvatarArtAuction.Auction;

    prepare(userAccount: AuthAccount) {
        self.nftCollectionRef = userAccount
                    .borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
                    ?? panic("Can not borrow NFT collection capability");

        self.auctionRef = userAccount
                    .borrow<&AvatarArtAuction.Auction>(from: AvatarArtAuction.AuctionStoragePath)
                    ?? panic("Can not borrow Auction capability");
    }

    execute {
        let nft <- self.nftCollectionRef.withdraw(withdrawID: tokenId) as! @AvatarArtNFT.NFT;

        self.auctionRef.createNewAuction(
          startTime: startTime,
          endTime: endTime,
          nft: <- nft)

        log("New auction created");
    }
}