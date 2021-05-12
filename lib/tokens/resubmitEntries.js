const resubmitAsset = require('./resubmitAsset');
const {getBlockchain} = require('../blockchain');

module.exports = async function resubmitEntries(stuckEntries) {
  const {contracts} = await getBlockchain();

  for (const entry of stuckEntries) {
    const {location, tokenId, transactionHash} = entry;

    console.log('Resubmitting chain transfer:', tokenId);

    try {
      const network = location.replace(/-stuck$/, '');
      const address = await contracts[network].NFT.methods.ownerOf(tokenId).call();

      await resubmitAsset(
        'NFT',
        network,
        'polygon',
        tokenId,
        transactionHash,
        address,
      );

      console.log('Successfully transferred.');
    } catch (err) {
      console.log('Transfer failed:');
      console.error(err);
    }
  }
};
