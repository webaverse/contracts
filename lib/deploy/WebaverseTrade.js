const Trade = artifacts.require('WebaverseTrade');
const {signer} = require('../const');

module.exports.deployTrade = async function(deployer, {erc20, erc721}) {
  console.log(':: Deploying Trade contract.');

  // Deploy.
  await deployer.deploy(Trade, erc20.address, erc721.address, signer);
  const trade = await Trade.deployed();

  // Log address.
  console.log('Deployed:' + trade.address);

  return trade;
};
