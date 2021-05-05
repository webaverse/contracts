
module.exports = function getTokenFromEvent(tokens, event) {
  return tokens.find(t => t.id === event.returnValues.tokenId);
};
