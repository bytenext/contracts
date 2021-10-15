import FungibleToken from 0x01
import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtTransactionInfo from 0x02
import BNU from 0x01
import AvatarArtAuction from 0x04

transaction (tokenId: UInt64, price: UFix64, startTime: UFix64, endTime: UFix64){
    let auctionRef: &AvatarArtAuction.Auction;

    prepare(userAccount: AuthAccount) {

        self.auctionRef = userAccount
                    .borrow<&AvatarArtAuction.Auction>(from: AvatarArtAuction.AuctionStoragePath)
                    ?? panic("Can not borrow Auction capability");
    }

    execute {
        self.auctionRef.userCreateNewAuction(
          tokenId: tokenId,
          price: price,
          startTime: startTime,
          endTime: endTime)

        log("New auction created");
    }
}