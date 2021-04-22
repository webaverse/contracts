const {getBlockchain} = require('./blockchain');
const {network} = require('./const');
const {runTransaction} = require('./runTransaction');


module.exports.getStatus = async function(address) {
  const {contracts, web3} = await getBlockchain();

  const fullAmount = {
    t: 'uint256',
    v: new web3.utils.BN(1e9)
      .mul(new web3.utils.BN(1e9))
      .mul(new web3.utils.BN(1e9)),
  };

  const fullAmountD2 = {
    t: 'uint256',
    v: fullAmount.v.div(new web3.utils.BN(2)),
  };

  // Get allowance for 10 silk.
  const allowance = new web3.utils.BN(
    await contracts[network].FT.methods.allowance(
      address,
      contracts[network].NFT._address
    ).call(),
    10
  );

  // Return approval status.
  return allowance.lt(fullAmountD2.v)
    ? (
      await runTransaction(
        'FT',
        'approve',
        contracts[network].NFT._address,
        fullAmount.v
      )
    ).status
    : true
}
