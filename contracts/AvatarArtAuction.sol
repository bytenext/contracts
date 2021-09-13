// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAvatarArtNftTransactionInfo.sol";
import "./AvatarArtBase.sol";

/**
* @dev Contract is used so that user can join an auction
* Business steps:
*   1. Artists submit auction information to system
*   2. Admin approve these informations and create an auction.
*   Note that: The submiting and approving will be processed outside blockchain
*   3. User joins the auction and winner will be the one who pay the highest price
*   4. At the end of auction, anyone can call `distribute` function to distribute NFT to the winner
*      If there is not winner, NFT will be payback to artist
*/
contract AvatarArtAuction is AvatarArtBase{
    enum EAuctionStatus{
        Open,
        Completed,
        Canceled
    }
    
    //Store information of specific auction
    struct Auction{
        uint256 startTime;
        uint256 endTime;
        address tokenOwner;
        uint256 price;
        address winner;
        address affiliate;
        EAuctionStatus status;       //0:Open, 1: Completed, 2: Canceled
    }
    
    //AUCTION 
    //Mapping tokenId and Auction list
    mapping(uint256 => Auction) public _auctions;       //List of auction
    
    constructor(address avatarArtNFTAddress, address transactionInfoAddress, address adminAddress) 
        AvatarArtBase(avatarArtNFTAddress, transactionInfoAddress, adminAddress){}
        
     /**
     * @dev {See - IAvatarArtAuction.createAuction}
     * 
     * IMPLEMENTATION
     *  1. Validate requirement
     *  2. Add new auction
     *  3. Transfer NFT to contract
     */ 
    function createAuction(uint256 tokenId, uint256 startTime, uint256 endTime, uint256 price) external onlyAdmin returns(bool){
        require(_now() <= startTime, "Start time is invalid");
        require(startTime < endTime, "Time is invalid");
        
        address tokenOwner = _avatarArtNFT.ownerOf(tokenId);
        _avatarArtNFT.safeTransferFrom(tokenOwner, address(this), tokenId);
        
        _auctions[tokenId] = Auction(startTime, endTime, tokenOwner, price, address(0), address(0), EAuctionStatus.Open);
        
        emit NewAuctionCreated(tokenId, startTime, endTime, price, _now());
        
        return true;
    }
    
    /**
     * @dev {See - IAvatarArtAuction.deactivateAuction}
     * 
     */ 
    function deactivateAuction(uint256 tokenId) external onlyAdmin returns(bool){
        require(tokenId > 0, "Invalid tokenId");
        _auctions[tokenId].status = EAuctionStatus.Canceled;
        emit AuctionDeactivated(tokenId, _now());
        return true;
    }
    
    /**
     * @dev {See - IAvatarArtAuction.distribute}
     * 
     *  IMPLEMENTATION
     *  1. Validate requirements
     *  2. Distribute NFT for winner
     *  3. Keep fee for dev and pay cost for token owner
     *  4. Update auction
     */ 
    function distribute(uint256 tokenId) external nonReentrant returns(bool){       //Anyone can call this function
        require(tokenId > 0, "Invalid tokenId");
        Auction storage auction = _auctions[tokenId];
        require(auction.status == EAuctionStatus.Open && auction.endTime < _now());

        address nftReceipentAddress = auction.tokenOwner;
        
        //If have auction
        if(auction.winner != address(0)){
            //Pay fee types and quantity for seller
            require(_processFee(tokenId, auction.price, auction.affiliate, auction.tokenOwner), "Can not pay fee");
            nftReceipentAddress = auction.winner;
        }

        //Transfer AvatarArtNFT from contract to winner
        _avatarArtNFT.safeTransferFrom(address(this), nftReceipentAddress, tokenId);
        
        auction.status = EAuctionStatus.Completed;

        emit Distributed(tokenId, nftReceipentAddress, _now());
        return true;
    }
    
    /**
     * @dev {See - IAvatarArtAuction.place}
     * 
     *  IMPLEMENTATION
     *  1. Validate requirements
     *  2. Add auction histories
     *  3. Update auction
     */ 
    function place(uint256 tokenId, uint256 price, address affiliate) external nonReentrant returns(bool){
        require(tokenId > 0, "Invalid tokenId");
        Auction storage auction = _auctions[tokenId];
        require(auction.status == EAuctionStatus.Open && auction.startTime <= _now() && auction.endTime >= _now(), "Invalid auction");
        require(price > auction.price, "Invalid price");

        IERC20 paymentToken = IERC20(_transactionInfo._paymentTokenAddresses(tokenId));
        //Transfer payment token to contract
        require(paymentToken.transferFrom(_msgSender(), address(this), price),"Payment token transferring failed");
        
        //If last user exised, pay back payment token
        if(auction.winner != address(0)){
            require(paymentToken.transfer(auction.winner, auction.price), "Can not payback for last winner");
        }
        
        //Update auction
        auction.winner = _msgSender();
        auction.price = price;
        auction.affiliate = affiliate;
        emit NewPlaceSetted(tokenId, _msgSender(), price, _now());
        
        return true;
    }
    
     /**
     * @dev {See - IAvatarArtAuction.updateAuctionPrice}
     * 
     */ 
    function updateAuctionPrice(uint256 tokenId, uint256 price) external onlyAdmin returns(bool){
        require(tokenId > 0, "Invalid tokenId");
        Auction storage auction = _auctions[tokenId];
        require(auction.startTime > _now());
        auction.price = price;
        
        emit AuctionPriceUpdated(tokenId, price, _now());
        return true;
    }
    
    /**
     * @dev {See - IAvatarArtAuction.updateAuctionTime}
     * 
     */ 
    function updateAuctionTime(uint256 tokenId, uint256 startTime, uint256 endTime) external onlyAdmin returns(bool){
        require(tokenId > 0, "Invalid tokenId");
        Auction storage auction = _auctions[tokenId];
        require(auction.startTime > _now());
        auction.startTime = startTime;
        auction.endTime = endTime;
        
        emit AuctionTimeUpdated(tokenId, startTime, endTime, _now());
        return true;
    }

    /**
     * @dev Owner withdraws ERC20 token from contract by `tokenAddress`
     */
    function withdrawToken(address tokenAddress) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_owner, token.balanceOf(address(this)));

        emit TokenWithdrawn(tokenAddress);
    }
    
    event NewAuctionCreated(uint256 tokenId, uint256 startTime, uint256 endTime, uint256 price, uint256 time);
    event AuctionPriceUpdated(uint256 tokenId, uint256 price, uint256 time);
    event AuctionTimeUpdated(uint256 tokenId, uint256 startTime, uint256 endTime, uint256 time);
    event AuctionDeactivated(uint256 tokenId, uint256 time);
    event NewPlaceSetted(uint256 tokenId, address account, uint256 price, uint256 time);
    event Distributed(uint256 tokenId, address winner, uint256 time);
    event TokenWithdrawn(address tokenAddress);

}