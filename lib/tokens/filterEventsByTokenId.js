
module.exports = function filterEventsByTokenId(events, tokenId) {
  return events.filter(e => {
    const id = parseInt(e.returnValues.tokenId, 10);
    return id === tokenId;
  });
};
