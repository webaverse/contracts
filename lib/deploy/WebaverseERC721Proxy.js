const ERC721Proxy = artifacts.require('WebaverseERC721Proxy');
const {network, signer} = require('../const');
const chainIds = require('../../config/chainIds');

module.exports.deployERC721Proxy = async function(deployer, {erc721}) {
  console.log(':: Deploying ERC721 Proxy contract.');

  // Deploy.
  await deployer.deploy(ERC721Proxy, erc721.address, signer, chainIds[network].ASSET);
  const erc721Proxy = await ERC721Proxy.deployed();

  // Log address.
  console.log('Deployed:' + erc721Proxy.address);

  return erc721Proxy;
};
