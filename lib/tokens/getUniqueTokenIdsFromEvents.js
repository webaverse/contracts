
module.exports = function getUniqueTokenIds(events) {
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
};
