// const Migrations = artifacts.require("Migrations");

// module.exports = function (deployer) {
//   deployer.deploy(Migrations);
// };

//ByteNextRouter
// const deployingContract = artifacts.require("ByteNextRouter");
// module.exports = function (deployer) {
//   deployer.deploy(deployingContract, "0xDC4823F36115971B1785f394d349601874677709","0x537ef1e31fF067f99Ac5f4e009991a7b4d86Bbc2");
// };

//ByteNextStakingInitializer
const deployingContract = artifacts.require("ByteNextStakingInitializer");

module.exports = function (deployer) {
  deployer.deploy(deployingContract);
};