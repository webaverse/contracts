const fetch = require('node-fetch');
const { runOffChainTransaction } = require( '../runOffChainTransaction' )
const { runTransaction } = require( '../runTransaction' )
const {getBlockchain} = require('../blockchain');

module.exports = async function resubmitAsset(
  contractName,
  network,
  destinationNetwork,
  tokenId,
  transactionHash,
  address,
  // offChainAddress,
) {
  // Determine correct address.
  // const destinationAddress = destinationNetwork === 'mainnetsidechain'
  //   ? address
  //   : offChainAddress;
  const destinationAddress = address;

  // Get tx signature.
  const res = await fetch(`https://sign.exokit.org/${network}/${contractName}/${destinationNetwork}/${transactionHash}`);
  const signatureJSON = await res.json();
  const {timestamp, r, s, v} = signatureJSON;

  if (destinationNetwork === 'mainnetsidechain') {
    // Withdraw token on sidechain.
    await runTransaction(contractName + 'Proxy', 'withdraw', destinationAddress, tokenId, timestamp, r, s, v);
  } else {
    // Withdraw token on another chain.
    // await runOffChainTransaction(destinationNetwork, contractName + 'Proxy', destinationAddress, 'withdraw', destinationAddress, tokenId, timestamp, r, s, v);
  }
};
