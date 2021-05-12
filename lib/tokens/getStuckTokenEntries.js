const cancelEntries = require('./cancelEntries');
const getAllWithdrawsDeposits = require('./getAllWithdrawsDeposits');
const getUniqueTokenIdsFromEvents = require('./getUniqueTokenIdsFromEvents');
const filterEventsByTokenId = require('./filterEventsByTokenId');
const {getBlockchain} = require('../blockchain');
const {filterUnique} = require('../util');

module.exports = async function getStuckTokenEntries(contractName) {
  const entries = await getAllWithdrawsDeposits(contractName);
  const {contracts} = await getBlockchain();

  const ids = entries
    .map(events => getUniqueTokenIdsFromEvents(events))
    .flat()
    .filter(filterUnique);

  return (await Promise.all(
    ids
      // Map each ID to a set of entries filtered by that token ID.
      .map(id => [id, entries.map(events => filterEventsByTokenId(events, id))])
      // Cancel each set of entries.
      .map(async e => {
        const tokenId = e[0];
        const sidechainMinterAddress = await contracts.mainnetsidechain.NFT.methods.getMinter(tokenId).call();
        const entry = cancelEntries(...e[1], sidechainMinterAddress);

        entry.tokenId = tokenId;

        return entry;
      }),
  ))
    // Only keep stuck tokens.
    .filter(e => e.location.includes('-stuck'));
};
