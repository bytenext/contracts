import AvatarArtTransactionInfo from "../contracts/AvatarArtTransactionInfo.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import BNU from "../contracts/BNU.cdc";
import FUSD from "../contracts/FUSD.cdc";
import FlowToken from "../contracts/FlowToken.cdc";

pub fun getCapability(address: Address?, path: PublicPath): Capability<&{FungibleToken.Receiver}>? {
    if(address != nil){
        return getAccount(address!).getCapability<&{FungibleToken.Receiver}>(path);
    }

    return nil
}


transaction(tokenId: UInt64,
    storingAddress: Address, insuranceAddress: Address, contractorAddress: Address, platformAddress: Address, authorAddress: Address,
    affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64) {

    let transactionAddressReference: &AvatarArtTransactionInfo.TransactionAddress;
    let feeInfoReference: &AvatarArtTransactionInfo.FeeInfo;


    prepare(adminAccount: AuthAccount) {
        self.transactionAddressReference = adminAccount.borrow<&AvatarArtTransactionInfo.TransactionAddress>(
            from: AvatarArtTransactionInfo.TransactionAddressStoragePath)
            ?? panic("could not borrow minter reference");

        self.feeInfoReference = adminAccount.borrow<&AvatarArtTransactionInfo.FeeInfo>(
            from: AvatarArtTransactionInfo.FeeInfoStoragePath)
            ?? panic("could not borrow minter reference");
    }

    execute {

        let currencies: {PublicPath: Type} = {
            /public/flowTokenReceiver: Type<@FlowToken.Vault>(),
            BNU.ReceiverPath: Type<@BNU.Vault>(),
            /public/fusdReceiver: Type<@FUSD.Vault>()
        }

        for path in currencies.keys {
            self.transactionAddressReference.setAddress(
                tokenId: tokenId,
                payType: currencies[path]!,
                storing: getCapability(address: storingAddress, path: path),
                insurance: getCapability(address: insuranceAddress, path: path),
                contractor: getCapability(address: contractorAddress, path: path),
                platform: getCapability(address: platformAddress, path: path),
                author: getCapability(address: authorAddress, path: path)
            )
        }


        self.feeInfoReference.setFee(
            tokenId: tokenId,
            affiliate: affiliate,
            storing: storing,
            insurance: insurance,
            contractor: contractor,
            platform: platform,
            author: author
        );

        log("Address setted");
    }
}