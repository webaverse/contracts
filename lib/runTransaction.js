const {default: Common} = require('@ethereumjs/common');
const {Transaction} = require('@ethereumjs/tx');
const {getBlockchain, getNonce} = require('./blockchain');
const {network} = require('./const');
const {createAsyncQueue} = require('./createAsyncQueue');

const txQueue = createAsyncQueue();

async function getSignedTx(contractName, method, ...args) {
  const {account, contracts, /* gasPrice, */ web3s} = await getBlockchain();
  // DEBUG
  const web3 = web3s.development;
  const gasPrice = parseInt(await web3.eth.getGasPrice(), 10);
  const contract = contracts[network][contractName];
  const {address, privateKey} = account;

  const txData = contract.methods[method](...args);

  const data = txData.encodeABI();
  // DEBUG
  // const gas = await txData.estimateGas({from: address});
  const gas = 0;
  // DEBUG
  // const nonce = await getNonce();
  const nonce = await web3.eth.getTransactionCount(address);
  const privateKeyBytes = Uint8Array.from(web3.utils.hexToBytes(privateKey));

  return Transaction.fromTxData({
    to: contract._address,
    nonce: '0x' + new web3.utils.BN(nonce).toString(16),
    gas: '0x' + new web3.utils.BN(gas).toString(16),
    gasPrice: '0x' + new web3.utils.BN(gasPrice).toString(16),
    gasLimit: '0x' + new web3.utils.BN(8000000).toString(16),
    data,
  }, {
    common: Common.forCustomChain(
      'mainnet',
      {
        name: 'geth',
        // TODO: Is this backwards or is truffle-config?
        networkId: 1,
        chainId: 1338,
      },
      'petersburg',
    ),
  }).sign(privateKeyBytes);
}

async function runTransaction(contractName, method, ...args) {
  return await txQueue.run(async () => {
    // DEBUG
    const {web3s} = await getBlockchain();
    const web3 = web3s.development;

    const tx = await getSignedTx(contractName, method, ...args);
    const rawTx = '0x' + tx.serialize().toString('hex');

    return web3.eth.sendSignedTransaction(rawTx);
  });
}

module.exports = {runTransaction};
