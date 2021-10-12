//import AvatarArtTransactionInfo from "./contracts/AvatarArtTransactionInfo.cdc"

import FungibleToken from 0x01
import AvatarArtTransactionInfo from 0x01
import BNU from 0x01

transaction(tokenId: UInt64,
    storingAddress: Address?, insuranceAddress: Address?, contractorAddress: Address?, platformAddress: Address?, authorAddress: Address?,
    affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64
    ) {

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

    execute{
        var storingCapability: Capability<&{FungibleToken.Receiver}>? = nil;
        if(storingAddress != nil){
            storingCapability = getAccount(storingAddress!).getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        }

        var insuranceCapability: Capability<&{FungibleToken.Receiver}>? = nil;
        if(insuranceAddress != nil){
            insuranceCapability = getAccount(insuranceAddress!).getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        }

        var contractorCapability: Capability<&{FungibleToken.Receiver}>? = nil;
        if(contractorAddress != nil){
            contractorCapability = getAccount(contractorAddress!).getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        }

        var platformCapability: Capability<&{FungibleToken.Receiver}>? = nil;
        if(platformAddress != nil){
            platformCapability = getAccount(platformAddress!).getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        }

        var authorCapability: Capability<&{FungibleToken.Receiver}>? = nil;
        if(authorAddress != nil){
            authorCapability = getAccount(authorAddress!).getCapability<&{FungibleToken.Receiver}>(BNU.ReceiverPath);
        }

        self.transactionAddressReference.setAddress(
            tokenId: tokenId,
            storing: storingCapability,
            insurance: insuranceCapability,
            contractor: contractorCapability,
            platform: platformCapability,
            author: authorCapability
        );

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