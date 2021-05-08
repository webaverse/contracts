const {getPastEvents} = require('../blockchain');
const {networks} = require('../const');
const {getDepositedEvents, getWithdrewEvents} = require('../events');

module.exports = async function getAllWithdrawsDeposits(contractName) {
  const proxyContract = `${contractName}Proxy`;

  return ( await Promise.all(
    networks.map(async n => {
      const events = await getPastEvents({
        network: n,
        contractName: proxyContract,
      });

      return [
        getDepositedEvents(events),
        getWithdrewEvents(events),
      ];
    }),
  )).flat();
};
