// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAvatarArtMarketplace.sol";
import "./AvatarArtBase.sol";

/**
* @dev Contract is used so that user can buy and sell NFT
* Business steps:
*   1. Artists submit selling information to system
*   2. Admin approve these informations and create an order.
*   3. If artist has any change, they can cancel this order
*   4. Other user can buy NFT by pay BNU token
*   Note that: The submiting and approving will be processed outside blockchain
*/
contract AvatarArtMarketplace is AvatarArtBase, IAvatarArtMarketplace{
    struct TokenInfo {
        address tokenOwner;
        uint256 price;
    }
    
    //uint256[] internal _tokens;
    
    //Mapping between tokenId and token info (price and owner)
    mapping(uint256 => TokenInfo) public _tokenInfos;
    
    constructor(address bnuTokenAddress, address avatarArtNFTAddress, address adminAddress) 
        AvatarArtBase(bnuTokenAddress, avatarArtNFTAddress, adminAddress){}
    
    /**
     * @dev Create a selling order to sell NFT
     */
    function createSellOrder(uint256 tokenId, uint256 price) external onlyAdmin override returns(bool){
        //Validate
        require(_tokenInfos[tokenId].tokenOwner == address(0), "Can not create sell order for this token");
        
        address tokenOwner = _avatarArtNFT.ownerOf(tokenId);
        
        //Transfer AvatarArtNFT to contract
        _avatarArtNFT.safeTransferFrom(tokenOwner, address(this), tokenId);
        
        _tokenInfos[tokenId].tokenOwner = tokenOwner;
        _tokenInfos[tokenId].price = price;
        
        emit NewSellOrderCreated(tokenId, _msgSender(), price, _now());
        
        return true;
    }

    /**
     * @dev See {IAvatarArtMarketplace.userCreateSellingOrder(tokenId, price);}
     */
    function userCreateSellingOrder(uint256 tokenId, uint256 price) external override nonReentrant returns(bool){
        TokenInfo storage tokenInfo = _tokenInfos[tokenId];
        //Validate
        require(tokenInfo.tokenOwner == _msgSender(), "Can not create sell order for this token");
        require(tokenInfo.price == 0, "This NFT is being sold");
        
        tokenInfo.price = price;
        
        emit NewSellOrderCreated(tokenId, _msgSender(), price, _now());
        
        return true;
    }
    
    /**
     * @dev User that created sell order can cancel that order
     * When user cancels a selling order, this NFT will be removed from marketplace and
     * transferred to user wallet
     */ 
    function cancelSellOrder(uint256 tokenId) external override nonReentrant returns(bool){
        TokenInfo storage tokenInfo = _tokenInfos[tokenId];
        require(tokenInfo.tokenOwner == _msgSender(), "Forbidden to cancel sell order");

        tokenInfo.price = 0;

        emit SellingOrderCanceled(tokenId, _msgSender(), _now());
        
        return true;
    }
    
    /**
     * @dev User purchases a BNU category
     */ 
    function purchase(uint tokenId, address affiliate) external override nonReentrant returns(uint){
        TokenInfo storage tokenInfo = _tokenInfos[tokenId];
        address tokenOwner = tokenInfo.tokenOwner;
        require(tokenOwner != address(0),"Token has not been added");
        require(tokenInfo.price > 0, "Token has not being sold");
        
        uint256 tokenPrice = tokenInfo.price;
        
        if(tokenPrice > 0){
            require(_processFeeFromSender(tokenId, tokenPrice, affiliate, tokenOwner, _msgSender()), "Can not pay fee");
        }
        
        tokenInfo.tokenOwner = _msgSender();
        tokenInfo.price = 0;

        emit Purchased(tokenId, _msgSender(), tokenOwner, tokenPrice, _now());
        
        return tokenPrice;
    }

    /**
     * @dev Owner withdraws ERC20 token from contract by `tokenAddress`
     */
    function withdrawToken(address tokenAddress) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_owner, token.balanceOf(address(this)));

        emit TokenWithdrawn(tokenAddress);
    }

    /**
     * @dev See {IAvatarArtMarketplace.withdrawNft(tokenId);}
     */
    function withdrawNft(uint256 tokenId) public override nonReentrant{
        TokenInfo storage tokenInfo = _tokenInfos[tokenId];
        require(tokenInfo.tokenOwner == _msgSender(), "Forbidden");
        require(tokenInfo.price == 0, "NFT is being sold");

        _avatarArtNFT.safeTransferFrom(address(this), _msgSender(), tokenId);

        tokenInfo.tokenOwner = address(0);
        emit NftWithdrawn(tokenId, _msgSender());
    }
    
    event NewSellOrderCreated(uint256 tokenId, address indexed seller, uint256 price, uint256 time);
    event Purchased(uint256 tokenId, address buyer,  address seller, uint256 price, uint256 time);
    event SellingOrderCanceled(uint256 tokenId, address account, uint256 time);
    event NewMarketHistory(address buyer, address seller, uint256 price, uint256 time);
    event TokenWithdrawn(address tokenAddress);
    event NftWithdrawn(uint256 tokenId, address account);
}