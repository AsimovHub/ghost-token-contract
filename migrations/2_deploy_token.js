const AsimovToken = artifacts.require("./AsimovToken.sol");

module.exports = (deployer) => {
    deployer.deploy(AsimovToken);
};