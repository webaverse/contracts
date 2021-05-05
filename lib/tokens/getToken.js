
const {getBlockchain} = require('../blockchain');
const {network} = require('../const');

module.exports = async function getToken(id, n = network) {
  const {contracts} = await getBlockchain();
  const token = await contracts[n].NFT.methods.tokenByIdFull(id).call();

  return {
    ...token,
    /* unlockable: (
      await contracts[n].NFT.methods
        .getMetadata(token.hash, 'unlockable').call()
    ) || '', */
  };
};
