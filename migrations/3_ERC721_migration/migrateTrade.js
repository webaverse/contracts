const {getBlockchain} = require('../../lib/blockchain');
const {network} = require('../../lib/const');
const {deployTrade} = require('../../lib/deploy/WebaverseTrade');
const {runTransaction} = require('../../lib/runTransaction');

module.exports.migrateTrade = async function(deployer, {erc20, erc721, redeploy = false}) {
  let trade;

  if (redeploy) {
    // Deploy.
    trade = await deployTrade(deployer, {erc20, erc721});
  } else {
    console.log(':: Migrating Trade contract.');

    // Get Trade contract.
    const {contracts} = await getBlockchain();
    trade = contracts[network].Trade;

    // Set parents.
    console.log('Setting new ERC20 parent for Trade contract.');
    await runTransaction(
      'Trade',
      'setERC20Parent',
      erc20.address,
    );

    console.log('Setting new ERC721 parent for Trade contract.');
    await runTransaction(
      'Trade',
      'setERC721Parent',
      erc721.address,
    );
  }

  return trade;
};
