const {getBlockchain} = require('../../lib/blockchain');
const {network} = require('../../lib/const');
const {runTransaction} = require('../../lib/runTransaction');

module.exports.migrateERC20Proxy = async function(erc20) {
  const {contracts} = await getBlockchain();

  // Set parent.
  console.log('Setting new ERC20Proxy parent.');
  await runTransaction(
    'FTProxy',
    'setERC20Parent',
    erc20.address,
  );

  return contracts[network].FTProxy;
};
