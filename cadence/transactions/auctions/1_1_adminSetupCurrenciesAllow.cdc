import AvatarArtTransactionInfo from "../../contracts/AvatarArtTransactionInfo.cdc";
import BNU from "../../contracts/BNU.cdc";
import FUSD from "../../contracts/FUSD.cdc";
import FlowToken from "../../contracts/FlowToken.cdc";
import AvatarArtTransactionInfo from "../../contracts/AvatarArtTransactionInfo.cdc";

transaction() {
  prepare(signer: AuthAccount) {
    let admin = signer.borrow<&AvatarArtTransactionInfo.Administrator>(from: AvatarArtTransactionInfo.AdminStoragePath)
          ?? panic("You are not admin")
    
    admin.setAcceptCurrencies(types: [
      Type<@BNU.Vault>(),
      Type<@FUSD.Vault>(),
      Type<@FlowToken.Vault>()
    ])
     
  }
}