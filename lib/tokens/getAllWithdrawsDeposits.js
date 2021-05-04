const {getPastEvents} = require('../blockchain');
const {getChainNames} = require('./getChainNames');

const eventNames = ['Deposited', 'Withdrew'];

module.exports.getAllWithdrawsDeposits = contractName => async chainName => {
  const proxyContract = `${contractName}Proxy`;

  const {
    mainnetChainName,
    sidechainChainName,
    polygonChainName,
  } = getChainNames(chainName);

  return await Promise.all(
    [
      mainnetChainName,
      sidechainChainName,
      polygonChainName,
    ].map(x => eventNames.map(e =>
      getPastEvents({
        network: x[0],
        contractName: proxyContract,
        eventName: e,
      }),
    )),
  );
};
