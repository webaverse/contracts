const ERC20Proxy = artifacts.require('WebaverseERC20Proxy');
const {network, signer} = require('../const');
const chainIds = require('../../config/chainIds');

module.exports.deployERC20Proxy = async function(deployer, {erc20}) {
  console.log(':: Deploying ERC20 Proxy contract.');

  // Deploy.
  await deployer.deploy(ERC20Proxy, erc20.address, signer, chainIds[network].SILK);
  const erc20Proxy = await ERC20Proxy.deployed();

  // Log address.
  console.log('Deployed:' + erc20Proxy.address);

  return erc20Proxy;
};
