const { default: Common } = require('@ethereumjs/common');
const { Transaction } = require('@ethereumjs/tx');
const {getBlockchain, getNonce} = require('./blockchain');
const {network} = require('./const');
const {createAsyncQueue} = require('./createAsyncQueue');

const txQueue = createAsyncQueue();

async function getSignedTx(contractName, method, ...args) {
  const {account, contracts, gasPrice, web3} = await getBlockchain();

  const gasPrice = parseInt(await web3.eth.getGasPrice(), 10);
  const contract = contracts[network][contractName];
  const {address, privateKey} = account;

  const txData = contract.methods[method](...args);

  const data = txData.encodeABI();
  const gas = await txData.estimateGas({from: address});
  const nonce = await getNonce();
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
    const {web3} = await getBlockchain();

    const tx = await getSignedTx(contractName, method, ...args);
    const rawTx = '0x' + tx.serialize().toString('hex');

    return await web3.eth.sendSignedTransaction(rawTx);
  })
}

module.exports = {runTransaction}
