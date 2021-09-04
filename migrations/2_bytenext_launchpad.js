const avatarArtLaunchpadContract = artifacts.require("AvatarArtLaunchpad");

module.exports = function (deployer) {
  deployer.deploy(
    avatarArtLaunchpadContract,
    "100000000000000000000000",
    500,
    "0x8b8fC08248CaEf8195C9A108f101b7eecDD35894",
    "0xc8CC8f17371Ea652Be178f1DeC9Cca9e57BbdCe2");
};