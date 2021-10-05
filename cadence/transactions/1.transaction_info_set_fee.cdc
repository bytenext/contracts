//import AvatarArtTransactionInfo from "./contracts/AvatarArtTransactionInfo.cdc"

import AvatarArtTransactionInfo from 0x01

transaction(tokenId: UInt64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64) {

    let feeInfoReference: &AvatarArtTransactionInfo.FeeInfo;

    prepare(adminAccount: AuthAccount) {
        self.feeInfoReference = adminAccount.borrow<&AvatarArtTransactionInfo.FeeInfo>(from: AvatarArtTransactionInfo.FeeInfoStoragePath)
            ?? panic("could not borrow minter reference");
    }

    execute{
        self.feeInfoReference.setFee(
            tokenId: tokenId,
            storing: storing,
            insurance: insurance,
            contractor: contractor,
            platform: platform,
            author: author
        );
        log("Fee setted");
    }
}