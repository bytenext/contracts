import NonFungibleToken from 0x01
import AvatarArtNFT from 0x01
import AvatarArtAuction from 0x04

transaction (tokenId: UInt64, price: UFix64, startTime: UFix64, endTime: UFix64){
    let auctionRef: &AvatarArtAuction.Auction;
    let nftReceiver: &AvatarArtNFT.Collection;

    prepare(userAccount: AuthAccount) {
        self.auctionRef = userAccount
                    .borrow<&AvatarArtAuction.Auction>(from: AvatarArtAuction.AuctionStoragePath)
                    ?? panic("Can not borrow Auction capability");
        self.nftReceiver = userAccount
                    .borrow<&AvatarArtNFT.Collection>(from: AvatarArtNFT.CollectionStoragePath)
                    ?? panic("Can not borrow Auction capability");
    }

    execute {
        let nft <- self.auctionRef.withdrawNFT(tokenId: tokenId);
        self.nftReceiver.deposit(token: <- nft);
    }
}