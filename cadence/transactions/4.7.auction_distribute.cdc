import AvatarArtAuction from 0x04
import AvatarArtTransactionInfo from 0x02

transaction (tokenId: UInt64, sellerAddress: Address, contractOwnerAddress: Address){
    let auctionRef: &{AvatarArtAuction.AuctionPublic};
    let feeRef: Capability<&{AvatarArtTransactionInfo.PublicFeeInfo}>;
    let feeRecepientRef: Capability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>;

    prepare(userAccount: AuthAccount) {
        self.auctionRef = getAccount(sellerAddress)
                    .getCapability<&{AvatarArtAuction.AuctionPublic}>(AvatarArtAuction.AuctionPublicPath)
                    .borrow()
                    ?? panic("Can not borrow AvatarArtAuction.Auction capability");
        
        let contractOwnerAccount = getAccount(contractOwnerAddress);
        self.feeRef = contractOwnerAccount
                        .getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(
                        AvatarArtTransactionInfo.FeeInfoPublicPath);

        self.feeRecepientRef = contractOwnerAccount
                        .getCapability<&{AvatarArtTransactionInfo.PublicTransactionAddress}>(
                        AvatarArtTransactionInfo.TransactionAddressPublicPath);
    }

    execute {
        self.auctionRef.distribute(
          tokenId: tokenId,
          feeReference: self.feeRef,
          feeRecepientReference: self.feeRecepientRef);
        log("NFT is distributed");
    }
}