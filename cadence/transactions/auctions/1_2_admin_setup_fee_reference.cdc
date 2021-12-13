import AvatarArtAuction from "../../contracts/AvatarArtAuction.cdc"
import AvatarArtTransactionInfo from "../../contracts/AvatarArtTransactionInfo.cdc"

transaction(owner: Address) {
  prepare(signer: AuthAccount) {
    let admin = signer.borrow<&AvatarArtAuction.Administrator>(from: AvatarArtAuction.AdminStoragePath)
          ?? panic("You are not admin")

    let contractOwner = getAccount(owner)
    let feeReference = contractOwner.getCapability<&AvatarArtTransactionInfo.FeeInfo{AvatarArtTransactionInfo.PublicFeeInfo}>(
      AvatarArtTransactionInfo.FeeInfoPublicPath
    )
    let feeRecipientReference = contractOwner.getCapability<&AvatarArtTransactionInfo.TransactionAddress{AvatarArtTransactionInfo.PublicTransactionAddress}>(
      AvatarArtTransactionInfo.TransactionAddressPublicPath
    )
     
    admin.setFeePreference(feeReference: feeReference, feeRecepientReference: feeRecipientReference)   
  }
}