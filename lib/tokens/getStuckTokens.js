const cancelEntries = require('./cancelEntries');
const getAllWithdrawsDeposits = require('./getAllWithdrawsDeposits');
const {signer} = require('../const');

// mainnetDepositedEntries = getTokenEvents(tokenId, mainnetDepositedEntries);
// mainnetWithdrewEntries = mainnetWithdrewEntries.filter(_filterByTokenIdLocal);
// sidechainDepositedEntries = sidechainDepositedEntries.filter(_filterByTokenIdLocal);
// sidechainWithdrewEntries = sidechainWithdrewEntries.filter(_filterByTokenIdLocal);
// polygonDepositedEntries = polygonDepositedEntries.filter(_filterByTokenIdLocal);
// polygonWithdrewEntries = polygonWithdrewEntries.filter(_filterByTokenIdLocal);

// console.log('filter by token id', tokenId, JSON.stringify({sidechainDepositedEntries}, null, 2));

module.exports = async function getStuckTokens(contractName, network) {
  const entries = await getAllWithdrawsDeposits(contractName, network);

  console.log('ENTRIES:', entries);

  // const result = cancelEntries(
  //   ...(await getAllWithdrawsDeposits('NFT')),
  //   signer,
  // );

  // mainnetDepositedEntries = result[0];
  // mainnetWithdrewEntries = result[1];
  // sidechainWithdrewEntries = result[2];
  // sidechainWithdrewEntries = result[3];
  // polygonDepositedEntries = result[4];
  // polygonWithdrewEntries = result[5];
  // const currentLocation = result[6];
  // sidechainMinterAddress = result[7];
  // const stuckTransactionHash = result[8];

  // console.log('STUCK:', result);
};
