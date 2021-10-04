// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAvatarArtArtistKYC{
    function isVerified(address account) external view returns(bool); 
}