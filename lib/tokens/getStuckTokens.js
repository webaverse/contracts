const cancelEntries = require('./cancelEntries');
const {signer} = require('../const');
const getAllWithdrawsDeposits = require('./getAllWithdrawsDeposits');
const getUniqueTokenIdsFromEvents = require('./getUniqueTokenIdsFromEvents');
const filterEventsByTokenId = require('./filterEventsByTokenId');
const {filterUnique} = require('../util');

function filterEntriesById(entries, id) {
  return entries.map(events => filterEventsByTokenId(events, id));
}

module.exports = async function getStuckTokens(contractName) {
  const entries = await getAllWithdrawsDeposits(contractName);

  const ids = entries
    .map(events => getUniqueTokenIdsFromEvents(events))
    .flat()
    .filter(filterUnique);

  const stuckEntries = ids
    // Map each ID to a set of entries filtered by that token ID.
    .map(id => entries.map(events => filterEventsByTokenId(events, id)))
    // Cancel each set of entries.
    .map(e => cancelEntries(...e, signer))
    // Only keep stuck tokens.
    .filter(e => e.location.includes('-stuck'));

  console.log('STUCK:', stuckEntries);

  // console.log('RESULT:', JSON.stringify(result));

  // mainnetDepositedEntries = result[0];
  // mainnetWithdrewEntries = result[1];
  // sidechainDepositedEntries = result[2];
  // sidechainWithdrewEntries = result[3];
  // polygonDepositedEntries = result[4];
  // polygonWithdrewEntries = result[5];
  // const currentLocation = result[6];
  // sidechainMinterAddress = result[7];
  // const stuckTransactionHash = result[8];

  return [];
};
