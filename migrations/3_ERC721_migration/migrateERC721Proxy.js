const {getBlockchain} = require('../../lib/blockchain');
const {deployERC721Proxy} = require('../../lib/deploy/WebaverseERC721Proxy');
const {network} = require('../../lib/const');
const {runTransaction} = require('../../lib/runTransaction');

module.exports.migrateERC721Proxy = async function(deployer, {erc721, redeploy = false}) {
  let erc721Proxy;

  if (redeploy) {
    // Deploy
    erc721Proxy = deployERC721Proxy(deployer, {erc721});
  } else {
    const {contracts} = await getBlockchain();
    erc721Proxy = contracts[network].NFTProxy;

    // Set parent.
    console.log('Setting new ERC721Proxy parent.');
    await runTransaction(
      'NFTProxy',
      'setERC721Parent',
      erc721.address,
    );
  }

  return erc721Proxy;
};
