const {cancelEntries} = require('./cancelEntries');

const _filterByTokenIdLocal = _filterByTokenId(tokenId);
mainnetDepositedEntries = mainnetDepositedEntries.filter(_filterByTokenIdLocal);
mainnetWithdrewEntries = mainnetWithdrewEntries.filter(_filterByTokenIdLocal);
sidechainDepositedEntries = sidechainDepositedEntries.filter(_filterByTokenIdLocal);
sidechainWithdrewEntries = sidechainWithdrewEntries.filter(_filterByTokenIdLocal);
polygonDepositedEntries = polygonDepositedEntries.filter(_filterByTokenIdLocal);
polygonWithdrewEntries = polygonWithdrewEntries.filter(_filterByTokenIdLocal);

// console.log('filter by token id', tokenId, JSON.stringify({sidechainDepositedEntries}, null, 2));

const result = cancelEntries(
  mainnetDepositedEntries,
  mainnetWithdrewEntries,
  sidechainDepositedEntries,
  sidechainWithdrewEntries,
  polygonDepositedEntries,
  polygonWithdrewEntries,
  sidechainMinterAddress,
);
mainnetDepositedEntries = result[0];
mainnetWithdrewEntries = result[1];
sidechainWithdrewEntries = result[2];
sidechainWithdrewEntries = result[3];
polygonDepositedEntries = result[4];
polygonWithdrewEntries = result[5];
const currentLocation = result[6];
sidechainMinterAddress = result[7];
const stuckTransactionHash = result[8];
