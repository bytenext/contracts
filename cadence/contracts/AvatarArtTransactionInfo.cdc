import FungibleToken from 0x01;

pub contract AvatarArtTransactionInfo {
    pub let FeeInfoStoragePath: StoragePath;
    pub let FeeInfoPublicPath: PublicPath;

    pub let TransactionAddressStoragePath: StoragePath;
    pub let TransactionAddressPublicPath: PublicPath;

    pub event FeeUpdated(tokenId: UInt64, affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64);
    pub event TransactionAddressUpdated(tokenId: UInt64, storing: Address?, insurance: Address?, contractor: Address?, platform: Address?, author: Address?);
    

    pub struct FeeInfoItem{
        pub let affiliate: UFix64;
        pub let storing: UFix64;
        pub let insurance: UFix64;
        pub let contractor: UFix64;
        pub let platform: UFix64;
        pub let author: UFix64;

        // initializer
        init (_affiliate: UFix64, _storing: UFix64, _insurance: UFix64, _contractor: UFix64, _platform: UFix64, _author: UFix64) {
            self.affiliate = _affiliate;
            self.storing = _storing;
            self.insurance = _insurance;
            self.contractor = _contractor;
            self.platform = _platform;
            self.author = _author;
        }
    }

    pub resource interface PublicFeeInfo{
        pub fun getFee(tokenId: UInt64): FeeInfoItem?;
    }

    pub resource FeeInfo : PublicFeeInfo{
        //Store fee for each NFT
        pub var fees: {UInt64: FeeInfoItem};

        pub fun setFee(tokenId: UInt64, affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64, author: UFix64){
            pre{
                tokenId > 0: "tokenId parameter is zero";
            }

            self.fees[tokenId] = FeeInfoItem(
                _affiliate: affiliate,
                _storing: storing,
                _insurance: insurance,
                _contractor: contractor,
                _platform: platform,
                _author: author);

            emit FeeUpdated(tokenId: tokenId, affiliate: affiliate, storing: storing, insurance: insurance, contractor: contractor, platform: platform, author: author);
        }

        pub fun getFee(tokenId: UInt64): FeeInfoItem?{
            pre{
                tokenId > 0: "tokenId parameter is zero";
            }

            return self.fees[tokenId];
        }

        // initializer
        init () {
            self.fees = {};
        }

        // destructor
        destroy() {
            //Do nothing
        }
    }
    
    pub struct TransactionRecipientItem{
        pub let storing: Capability<&{FungibleToken.Receiver}>?;
        pub let insurance: Capability<&{FungibleToken.Receiver}>?;
        pub let contractor: Capability<&{FungibleToken.Receiver}>?;
        pub let platform: Capability<&{FungibleToken.Receiver}>?;
        pub let author: Capability<&{FungibleToken.Receiver}>?;

        // initializer
        init (_storing: Capability<&{FungibleToken.Receiver}>?, 
            _insurance: Capability<&{FungibleToken.Receiver}>?, 
            _contractor: Capability<&{FungibleToken.Receiver}>?, 
            _platform: Capability<&{FungibleToken.Receiver}>?, 
            _author: Capability<&{FungibleToken.Receiver}>?) {
            self.storing = _storing;
            self.insurance = _insurance;
            self.contractor = _contractor;
            self.platform = _platform;
            self.author = _author;
        }
    }

    pub resource interface PublicTransactionAddress{
        pub fun getAddress(tokenId: UInt64): TransactionRecipientItem?;
    }

    pub resource TransactionAddress : PublicTransactionAddress{
        //Store fee for each NFT
        pub var addresses: {UInt64: TransactionRecipientItem};

        pub fun setAddress(tokenId: UInt64,
            storing: Capability<&{FungibleToken.Receiver}>?, 
            insurance: Capability<&{FungibleToken.Receiver}>?, 
            contractor: Capability<&{FungibleToken.Receiver}>?, 
            platform: Capability<&{FungibleToken.Receiver}>?, 
            author: Capability<&{FungibleToken.Receiver}>?){
            pre{
                tokenId > 0: "tokenId parameter is zero";
            }

            self.addresses[tokenId] = TransactionRecipientItem(
                _storing: storing,
                _insurance: insurance,
                _contractor: contractor,
                _platform: platform,
                _author: author);

            var storingAddress: Address? = nil;
            if(storing != nil){storingAddress = storing!.address};

            var insuranceAddress: Address? = nil;
            if(insurance != nil){insuranceAddress = insurance!.address};

            var contractorAddress: Address? = nil;
            if(contractor != nil){contractorAddress = contractor!.address};

            var platformAddress: Address? = nil;
            if(platform != nil){platformAddress = platform!.address};

            var authorAddress: Address? = nil;
            if(author != nil){authorAddress = author!.address};

            emit TransactionAddressUpdated(tokenId: tokenId, storing: storingAddress,
                   insurance: insuranceAddress, contractor: contractorAddress, platform: platformAddress, author: authorAddress);
        }

        pub fun getAddress(tokenId: UInt64): TransactionRecipientItem?{
            pre{
                tokenId > 0: "tokenId parameter is zero";
            }

            return self.addresses[tokenId];
        }

        // initializer
        init () {
            self.addresses = {};
        }

        // destructor
        destroy() {
            //Do nothing
        }
    }

    init(){
        self.FeeInfoStoragePath = /storage/avatarArtTransactionInfoFeeInfo;
        self.FeeInfoPublicPath = /public/avatarArtTransactionInfoFeeInfo;

        self.TransactionAddressStoragePath = /storage/avatarArtTransactionInfoRecepientAddress;
        self.TransactionAddressPublicPath = /public/avatarArtTransactionInfoRecepientAddress;

        let feeInfo <- create FeeInfo();
        self.account.save(<- feeInfo, to: self.FeeInfoStoragePath);

        self.account.link<&AvatarArtTransactionInfo.FeeInfo{AvatarArtTransactionInfo.PublicFeeInfo}>(
            AvatarArtTransactionInfo.FeeInfoPublicPath,
            target: AvatarArtTransactionInfo.FeeInfoStoragePath);

        let transactionAddress <- create TransactionAddress();
        self.account.save(<- transactionAddress, to: self.TransactionAddressStoragePath);

        self.account.link<&AvatarArtTransactionInfo.TransactionAddress{AvatarArtTransactionInfo.PublicTransactionAddress}>(
            AvatarArtTransactionInfo.TransactionAddressPublicPath,
            target: AvatarArtTransactionInfo.TransactionAddressStoragePath);
    }
}