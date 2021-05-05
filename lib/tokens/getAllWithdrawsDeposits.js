const {getEventsRated} = require('../blockchain');
const {networks} = require('../const');
const {pull} = require('../util');

module.exports = async function getAllWithdrawsDeposits(contractName, skip = '') {
  const proxyContract = `${contractName}Proxy`;
  // const ns = skip ? pull(networks, skip) : networks;
  const ns = ['mainnet', 'mainnetsidechain']

  // TODO: Parallelize
  return await Promise.all(
    ns.map(async n => [
      await getEventsRated({
        network: n,
        contractName: proxyContract,
        eventName: 'Deposited',
      }),

      await getEventsRated({
        network: n,
        contractName: proxyContract,
        eventName: 'Withdrew',
      }),
    ]),
  );
};
