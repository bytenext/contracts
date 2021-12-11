// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./core/Ownable.sol";

/**
* @dev Verify and unverify Artist KYC information
* This approvement will be used to verify KYC so that Artist can create their own NFTs
*/
contract AvatarArtArtistKYC is Ownable{
    mapping(address => bool) private _isVerifieds;
    
    function isVerified(address account) external view returns(bool){
        return _isVerifieds[account];
    }
    
    /**
    * @dev Toogle artists' KYC verification status
    * Note that: Only owner can send request
     */
    function toggleVerify(address account) external onlyOwner{
        _isVerifieds[account] = !_isVerifieds[account];
        emit VerificationToggled(account, _isVerifieds[account]);
    }

    event VerificationToggled(address account, bool verified);
}