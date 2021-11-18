import FungibleToken from 0x01;

pub contract BNULaunchpad {
    pub let LaunchpadStoragePath: StoragePath;
    pub let LaunchpadPublicPath: PublicPath;

    pub struct LaunchpadInfo{
        pub(set) var _startTime: UFix64;
        pub(set) var _endTime: UFix64;
        pub(set) var _tokenPrice: UFix64;
        pub(set) var _tokenType: Type;
        pub(set) var _paymentType: Type;
        pub var _totalBought: UFix64;
        pub(set) var _userAllocations: {Address: UFix64};
        pub(set) var _userBoughts: {Address: UFix64};
        pub var _tokenReceiver: Capability<&{FungibleToken.Receiver}>;

        pub(set) var _claimingTimes: [UFix64];
        pub(set) var _claimingPercents: [UFix64];
        pub(set) var _claimingCounts: {Address: Int};

        init(startTime: UFix64, endTime: UFix64, tokenPrice: UFix64,
            tokenType: Type, paymentType: Type, tokenReceiver: Capability<&{FungibleToken.Receiver}>,
            claimingTimes: [UFix64], claimingPercents: [UFix64])  {
            self._startTime = startTime;
            self._endTime = endTime;
            self._tokenPrice = tokenPrice;
            self._tokenType = tokenType;
            self._paymentType = paymentType;
            self._totalBought = 0.0;
            self._tokenReceiver = tokenReceiver;

            self._userAllocations = {};
            self._userBoughts = {};

            self._claimingTimes = claimingTimes;
            self._claimingPercents = claimingPercents;
            self._claimingCounts = {};
        }

        pub fun setTotalBought(_ value: UFix64){
            self._totalBought = value;
        }
    }
  
    pub resource interface LaunchpadPublic {
        pub fun join(id: Int, paymentVault: @FungibleToken.Vault);
        pub fun claim(id: Int, tokenReceiver: Capability<&{FungibleToken.Receiver}>); 
        pub fun getLaunchpadCount(): Int;
        pub fun getLaunchpadInfo(id: Int): LaunchpadInfo?;
        pub fun getUserAllocation(id: Int, _ account: Address): UFix64;
        pub fun getClaimable(id: Int, _ account: Address): UFix64;
    }

  pub resource Launchpad: LaunchpadPublic {
    //The number of launchpad
    access(self) var _launchpadCount: Int;

    //Dictionary that stores launchpad information
    access(self) var _launchpads: {Int: LaunchpadInfo};

    access(self) var _launchpadTokens: @{Int: FungibleToken.Vault};

    init() {
        self._launchpadCount = 0;
        self._launchpads = {};
        self._launchpadTokens <- {};
    }

    pub fun createNewLaunchpad(startTime: UFix64, endTime: UFix64, 
        tokenPrice: UFix64, tokenType: Type,
        paymentType: Type, tokenReceiver: Capability<&{FungibleToken.Receiver}>,
        claimingTimes: [UFix64], claimingPercents: [UFix64]){
        pre{
            startTime < endTime: "startTime should be less than endTime";
        }
        self._launchpadCount = self._launchpadCount + 1;
        self._launchpads[self._launchpadCount] =  LaunchpadInfo(
            startTime: startTime,
            endTime: endTime,
            tokenPrice: tokenPrice,
            tokenType: tokenType,
            paymentType: paymentType,
            tokenReceiver: tokenReceiver,
            claimingTimes: claimingTimes,
            claimingPercents: claimingPercents);

        emit NewLauchpadCreated(id: self._launchpadCount, startTime: startTime, endTime: endTime, tokenType: tokenType, paymentType: paymentType);
    }

    pub fun setTime(id: Int, startTime: UFix64, endTime: UFix64){
        pre{
            startTime < endTime: "startTime should be less than endTime";
        }

        var launchpadInfo = self._launchpads[id]!;
        launchpadInfo._startTime = startTime;
        launchpadInfo._endTime = startTime;
        self._launchpads[id] = launchpadInfo;

        emit LaunchpadTimeUpdated(id: id, startTime: startTime, endTime: endTime);
    }

    pub fun setUserAllocation(id: Int, account: Address, allocation: UFix64){
        pre{
            self.getLaunchpadInfo(id: id) != nil: "Invalid launchpad id";
            allocation > 0.0: "Allocation should be greater than 0";
        }

        self._launchpads[id]!._userAllocations.remove(key: account);
        self._launchpads[id]!._userAllocations.insert(key: account, allocation);

        emit UserAllocationSetted(id: id, account: account, allocation: allocation);
    }

    //PUBLIC FUNCTIONS
    pub fun getLaunchpadCount(): Int{
        return self._launchpadCount;
    }

    pub fun getLaunchpadInfo(id: Int): LaunchpadInfo?{
        return self._launchpads[id];
    }

    pub fun getUserAllocation(id: Int,_ account: Address): UFix64{
        let launchpadInfo : LaunchpadInfo? = self.getLaunchpadInfo(id: id);
        if(launchpadInfo == nil){
            return 0.0;
        }
        
        let userAllocation = launchpadInfo!._userAllocations[account];
        if(userAllocation == nil){
            return 0.0;
        }

        return userAllocation!;
    }

    pub fun getClaimable(id: Int, _ account: Address): UFix64{
        if(self.getLaunchpadInfo(id: id) == nil) {return 0.0;}
        let launchpadInfo : LaunchpadInfo = self.getLaunchpadInfo(id: id)!;
        let now: UFix64 =  getCurrentBlock().timestamp;
        if(now <= launchpadInfo._endTime){
            return 0.0;
        }

        let userBought: UFix64 = launchpadInfo._userBoughts[account]!;
        if(userBought == nil || userBought == 0.0){
            return 0.0;
        }

        let claimingTimeLength: Int = launchpadInfo._claimingTimes.length;

        if(claimingTimeLength == 0){
            return 0.0;
        }

        if(getCurrentBlock().timestamp < launchpadInfo._claimingTimes[0]){
            return 0.0;
        }

        var startIndex: Int = launchpadInfo._claimingCounts[account] ?? 0;
        if(startIndex >= claimingTimeLength){
            return 0.0;
        }

        var tokenQuantity: UFix64 = 0.0;
        var index: Int = 0;
        while(index < claimingTimeLength){
            let claimingTime: UFix64 = launchpadInfo._claimingTimes[index];
            if(now >= claimingTime){
                tokenQuantity = tokenQuantity + userBought * launchpadInfo._claimingPercents[index] / 100.0;
            }else{
                break;
            }
            index = index + 1;
        }

        return tokenQuantity;
    }

    pub fun join(id: Int, paymentVault: @FungibleToken.Vault){
        pre{
            self.getLaunchpadInfo(id: id) != nil: "Launchpad id is invalid";
            self.getUserAllocation(id: id, paymentVault.owner!.address) > 0.0: "You can not join this launchpad";
            paymentVault.isInstance(self.getLaunchpadInfo(id: id)!._paymentType):
                    "Payment token is not allowed";
        }

        let launchpadInfo : LaunchpadInfo = self.getLaunchpadInfo(id: id)!;
        if(launchpadInfo._startTime > getCurrentBlock().timestamp || launchpadInfo._endTime < getCurrentBlock().timestamp){
            panic("Can not join this launchpad at this time");
        }

        let account: Address = paymentVault.owner!.address;
        var tokenToBuy = paymentVault.balance / launchpadInfo._tokenPrice;
        var userBought: UFix64 = 0.0;
        if(launchpadInfo._userBoughts[account] == nil){
            userBought = 0.0;
        }
        else{
            userBought = launchpadInfo._userBoughts[account]!;
        }
        let maxTokenToBuy = launchpadInfo._userAllocations[account]! - userBought;
        if(maxTokenToBuy == 0.0){
            panic("You can not join this launchpad anymore");
        }
        if(maxTokenToBuy < tokenToBuy){
            panic("Out of allocation");
        }

        var maxPaymentToken: UFix64 = maxTokenToBuy * launchpadInfo._tokenPrice;
        if(maxPaymentToken > paymentVault.balance){
            maxPaymentToken = paymentVault.balance;
        }

        tokenToBuy = maxPaymentToken / launchpadInfo._tokenPrice;

        self._launchpads[id]!._userBoughts.remove(key: account);
        self._launchpads[id]!._userBoughts.insert(key: account, userBought + tokenToBuy);
        self._launchpads[id]!.setTotalBought(self._launchpads[id]!._totalBought + tokenToBuy);

        launchpadInfo._tokenReceiver.borrow()!.deposit(from: <- paymentVault);

        emit Joined(account: account, id: id, tokenQuantity: tokenToBuy);
    }

    pub fun claim(id: Int, tokenReceiver: Capability<&{FungibleToken.Receiver}>){
        pre{
            self.getLaunchpadInfo(id: id) != nil: "Launchpad id is invalid";
            self.getUserAllocation(id: id, tokenReceiver.address) > 0.0: "You can not join this launchpad";
        }

        let launchpadInfo : LaunchpadInfo = self.getLaunchpadInfo(id: id)!;
        let now: UFix64 =  getCurrentBlock().timestamp;
        if(now <= launchpadInfo._endTime){
            panic("Can not claim token of this launchpad at this time");
        }

        let account: Address = tokenReceiver.address;

        let userBought: UFix64 = launchpadInfo._userBoughts[account]!;
        if(userBought == nil || userBought == 0.0){
            panic("You can not claim for this launchpad");
        }

        let claimingTimeLength: Int = launchpadInfo._claimingTimes.length;

        if(claimingTimeLength == 0){
            panic("Can not claim at this time");
        }

        if(getCurrentBlock().timestamp < launchpadInfo._claimingTimes[0]){
            panic("Can not claim at this time");
        }

        var startIndex: Int = launchpadInfo._claimingCounts[account] ?? 0;
        if(startIndex >= claimingTimeLength){
            panic("You have claimed all token");
        }

        var tokenQuantity: UFix64 = 0.0;
        var index: Int = 0;
        while(index < claimingTimeLength){
            let claimingTime: UFix64 = launchpadInfo._claimingTimes[index];
            if(now >= claimingTime){
                tokenQuantity = tokenQuantity + userBought * launchpadInfo._claimingPercents[index] / 100.0;
                let claimingCount: Int = self._launchpads[id]!._claimingCounts[account] ?? 0;
                self._launchpads[id]!._claimingCounts.remove(key:account);
                self._launchpads[id]!._claimingCounts.insert(key:account, claimingCount + 1);
            }else{
                break;
            }
            index = index + 1;
        }

        if(tokenQuantity > 0.0){
            let token <- self._launchpadTokens.remove(key: id)!;

            let claimingToken <- token.withdraw(amount: tokenQuantity);
            tokenReceiver.borrow()!.deposit(from: <- claimingToken);

            let oldToken <- self._launchpadTokens.insert(key: id, <- token);
            destroy  oldToken;
        }

        emit Claimed(account: account, id: id, tokenQuantity: tokenQuantity);
    }
    
    destroy() {
        destroy self._launchpadTokens;
    }
  }

    init(){
        self.LaunchpadStoragePath = /storage/byteNextBnuLaunchpad;
        self.LaunchpadPublicPath = /public/byteNextPublicBnuLaunchpad;

        self.account.save(<- create Launchpad(), to: self.LaunchpadStoragePath);
        self.account.link<&Launchpad{LaunchpadPublic}>(self.LaunchpadPublicPath, target: self.LaunchpadStoragePath);
    }

    pub event NewLauchpadCreated(id: Int, startTime: UFix64, endTime: UFix64, tokenType: Type, paymentType: Type);
    pub event LaunchpadTimeUpdated(id: Int, startTime: UFix64, endTime: UFix64);
    pub event UserAllocationSetted(id: Int, account: Address, allocation: UFix64);
    pub event Joined(account: Address, id: Int, tokenQuantity: UFix64);
    pub event Claimed(account: Address, id: Int, tokenQuantity: UFix64);
}