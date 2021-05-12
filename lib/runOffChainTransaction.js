const {getBlockchain} = require('./blockchain');

module.exports.runOffChainTransaction = async (chainName, contractName, address, method, ...args) => {
  const {contracts} = await getBlockchain();
  const m = contracts[chainName][contractName].methods[method];

  return await m.apply(m, args).send({
    from: address,
  });
};
