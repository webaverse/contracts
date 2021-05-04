const {getBlockchain} = require('./blockchain');
const {network} = require('./const');

// TODO: Why?
const _copy = o => {
  const oldO = o;
  // copy array
  const newO = JSON.parse(JSON.stringify(oldO));
  // decorate array
  for (const k in oldO) {
    newO[k] = oldO[k];
  }
  return newO;
};

async function getToken(id, n = network) {
  const {contracts} = await getBlockchain();

  const token = _copy(
    await contracts[n].NFT.methods.tokenByIdFull(id).call(),
  );

  return {
    ...token,
    unlockable: (
      await contracts[n].NFT.methods
        .getMetadata(token.hash, 'unlockable').call()
    ) || '',
  };
}

function getTokenEvents(id, events) {
  let tokenId;

  return events
    .map(event => {
      tokenId = event.returnValues.tokenId;

      if (typeof tokenId === 'string') {
        return parseInt(tokenId, 10) === id
          ? event
          : null;
      } else return null;
    })
    .filter(e => e !== null);
}

function getTokenFromEvent(tokens, event) {
  return tokens.find(t => t.id === event.returnValues.tokenId);
}

async function getTokens(events, n = network) {
  return (await Promise.all(
    getUniqueTokenIds(events)
      .map(id => getToken(id, n)),
  ));
  // Drop burned tokens.
  // .filter(t => !isBurned(t.owner.address))
}

function getUniqueTokenIds(events) {
  const seenTokenIds = {};

  return events.map(event => {
    let {tokenId} = event.returnValues;

    if (typeof tokenId === 'string') {
      tokenId = parseInt(tokenId, 10);

      if (!seenTokenIds[tokenId]) {
        seenTokenIds[tokenId] = true;
        return tokenId;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }).filter(tokenId => tokenId !== null);
}

function isSingleIssue(token) {
  return token.totalSupply === 1;
}

module.exports = {
  getTokenEvents,
  getTokenFromEvent,
  getTokens,
};
