const GhostToken = artifacts.require("GhostToken");

module.exports = (deployer) => {
    deployer.deploy(GhostToken);
};