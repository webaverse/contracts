const {deployERC20Proxy} = require('../../lib/deploy/WebaverseERC20Proxy');
const {getBlockchain} = require('../../lib/blockchain');
const {network} = require('../../lib/const');
const {runTransaction} = require('../../lib/runTransaction');

module.exports.migrateERC20Proxy = async function(deployer, {erc20, redeploy = false}) {
  let erc20Proxy;

  if (redeploy) {
    erc20Proxy = deployERC20Proxy(deployer, {erc20});
  } else {
    const {contracts} = await getBlockchain();
    erc20Proxy = contracts[network].FTProxy;

    // Set parent.
    console.log('Setting new ERC20Proxy parent.');
    await runTransaction(
      'FTProxy',
      'setERC20Parent',
      erc20.address,
    );
  }

  return erc20Proxy;
};
