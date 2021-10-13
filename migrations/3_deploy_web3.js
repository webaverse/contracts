const Webaverse = artifacts.require("Webaverse.sol");

module.exports = function (deployer) {
    deployer.deploy(Webaverse);
};
