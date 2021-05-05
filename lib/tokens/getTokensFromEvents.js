const getToken = require('./getToken');
const getUniqueTokenIdsFromEvents = require('./getUniqueTokenIdsFromEvents');
const {network} = require('../const');

module.exports = async function getTokensFromEvents(events, n = network) {
  return (await Promise.all(
    getUniqueTokenIdsFromEvents(events)
      .map(id => getToken(id, n)),
  ));
};
