import AvatarArtTransactionInfo from 0x02

pub fun main(tokenId: UInt64): AvatarArtTransactionInfo.FeeInfoItem? {
    let publicAccount = getAccount(0x01)

    let feeInfoReference = publicAccount.getCapability<&{AvatarArtTransactionInfo.PublicFeeInfo}>(AvatarArtTransactionInfo.FeeInfoCapabilityPublicPath)
                            .borrow()
                            ?? panic("Could not borrow a reference to the hello capability");

    return feeInfoReference.getFee(tokenId: tokenId);
}