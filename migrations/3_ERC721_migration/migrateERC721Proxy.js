const {getBlockchain} = require('../../lib/blockchain');
const {network} = require('../../lib/const');
const {runTransaction} = require('../../lib/runTransaction');

module.exports.migrateERC721Proxy = async function(erc721) {
  const {contracts} = await getBlockchain();

  // Set parent.
  console.log('Setting new ERC721Proxy parent.');
  await runTransaction(
    'NFTProxy',
    'setERC721Parent',
    erc721.address,
  );

  return contracts[network].NFTProxy;
};
