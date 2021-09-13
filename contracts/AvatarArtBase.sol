// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAvatarArtNftTransactionInfo.sol";
import "./interfaces/IFeeInfo.sol";
import "./core/Ownable.sol";
import "./core/ReentrancyGuard.sol";

contract AvatarArtBase is Ownable, IERC721Receiver, IFeeInfo, ReentrancyGuard{
    modifier onlyAdmin{
        require(_msgSender() == _adminAddress, "Only admin");
        _;
    }

    uint256 public MULTIPLIER = 1000;

    address public _adminAddress;
    
    IERC721 public _avatarArtNFT;    
    IAvatarArtNftTransactionInfo public _transactionInfo;
    
    constructor(address avatarArtNFTAddress, address transactionInfoAddress, address adminAddress){
        _avatarArtNFT = IERC721(avatarArtNFTAddress);
        _transactionInfo = IAvatarArtNftTransactionInfo(transactionInfoAddress);
        _adminAddress = adminAddress;
    }
    
    /**
     * @dev Set AvatarArtNFT contract 
     */
    function setAvatarArtNFT(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        _avatarArtNFT = IERC721(newAddress);
    }

    /**
     * @dev Set admin address
     */
    function setAdminAddress(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        _adminAddress = newAddress;
    }

    /**
     * @dev Set AvatarArtNftTransactionInfo contract 
     */
    function setAvatarArtNftTransactionInfo(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        _transactionInfo = IAvatarArtNftTransactionInfo(newAddress);
    }

    function _processFee(uint256 tokenId, uint256 price, address affiliateAddress, address receipent) internal virtual returns(bool){
        address paymentTokenAddress = _transactionInfo._paymentTokenAddresses(tokenId);
        require(paymentTokenAddress != address(0), "Payment address is zero");

        FeeInfo memory feeInfo = _transactionInfo.getFee(tokenId);
        FeeReceipentAddress memory feeReceipentAddress = _transactionInfo.getFeeReceipentAddresses(tokenId);
        uint256 multiplier = _transactionInfo.MULTIPLIER();

        IERC20 paymentToken = IERC20(paymentTokenAddress);

        uint256 feeTotal = 0;
        if(affiliateAddress != address(0) && feeInfo.affiliate > 0){
            uint256 fee = price * feeInfo.affiliate / multiplier / 100;
            paymentToken.transfer(affiliateAddress, fee);
            feeTotal += fee;
        }

        if(feeReceipentAddress.storing != address(0) && feeInfo.storing > 0){
            uint256 fee = price * feeInfo.storing / multiplier / 100;
            paymentToken.transfer(feeReceipentAddress.storing, fee);
            feeTotal += fee;
        }

        if(feeReceipentAddress.insurance != address(0) && feeInfo.insurance > 0){
            uint256 fee = price * feeInfo.insurance / multiplier / 100;
            paymentToken.transfer(feeReceipentAddress.insurance, fee);
            feeTotal += fee;
        }

        if(feeReceipentAddress.contractor != address(0) && feeInfo.contractor > 0){
            uint256 fee = price * feeInfo.contractor / multiplier / 100;
            paymentToken.transfer(feeReceipentAddress.contractor, fee);
            feeTotal += fee;
        }

        if(feeReceipentAddress.author != address(0) && feeInfo.author > 0){
            uint256 fee = price * feeInfo.author / multiplier / 100;
            paymentToken.transfer(feeReceipentAddress.author, fee);
            feeTotal += fee;
        }

        if(feeInfo.platform > 0){
            uint256 fee = price * feeInfo.platform / multiplier / 100;
            paymentToken.transfer(_transactionInfo._avatarArtPlatformAddress(), fee);
            feeTotal += fee;
        }

        //Left is for seller
        paymentToken.transfer(receipent, price - feeTotal);
        return true;
    }

    function _processFeeFromSender(uint256 tokenId, uint256 price, address affiliateAddress, address receipent, address sender) internal virtual returns(bool){
        address paymentTokenAddress = _transactionInfo._paymentTokenAddresses(tokenId);
        require(paymentTokenAddress != address(0), "Payment address is zero");

        FeeInfo memory feeInfo = _transactionInfo.getFee(tokenId);
        FeeReceipentAddress memory feeReceipentAddress = _transactionInfo.getFeeReceipentAddresses(tokenId);
        uint256 multiplier = _transactionInfo.MULTIPLIER();

        IERC20 paymentToken = IERC20(paymentTokenAddress);

        uint256 feeTotal = 0;
        if(affiliateAddress != address(0) && feeInfo.affiliate > 0){
            uint256 fee = price * feeInfo.affiliate / multiplier / 100;
            paymentToken.transferFrom(sender, affiliateAddress, fee);
            feeTotal += fee;
        }

        if(feeReceipentAddress.storing != address(0) && feeInfo.storing > 0){
            uint256 fee = price * feeInfo.storing / multiplier / 100;
            paymentToken.transferFrom(sender, feeReceipentAddress.storing, fee);
            feeTotal += fee;
        }

        if(feeReceipentAddress.insurance != address(0) && feeInfo.insurance > 0){
            uint256 fee = price * feeInfo.insurance / multiplier / 100;
            paymentToken.transferFrom(sender, feeReceipentAddress.insurance, fee);
            feeTotal += fee;
        }

        if(feeReceipentAddress.contractor != address(0) && feeInfo.contractor > 0){
            uint256 fee = price * feeInfo.contractor / multiplier / 100;
            paymentToken.transferFrom(sender, feeReceipentAddress.contractor, fee);
            feeTotal += fee;
        }

        if(feeReceipentAddress.author != address(0) && feeInfo.author > 0){
            uint256 fee = price * feeInfo.author / multiplier / 100;
            paymentToken.transferFrom(sender, feeReceipentAddress.author, fee);
            feeTotal += fee;
        }

        if(feeInfo.platform > 0){
            uint256 fee = price * feeInfo.platform / multiplier / 100;
            paymentToken.transferFrom(sender, _transactionInfo._avatarArtPlatformAddress(), fee);
            feeTotal += fee;
        }

        //Left is for seller
        paymentToken.transferFrom(sender, receipent, price - feeTotal);
        return true;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}