const {getBlockchain} = require('./blockchain');
const {runTransaction} = require('./runTransaction');
const {getStatus} = require('./getStatus');

async function mintERC721(contract, token) {
  const {account} = await getBlockchain();
  const status = await getStatus(account.address);

  if (status) {
    return await runTransaction(
      'NFT',
      'mint',
      account.address,
      token.hash,
      token.name,
      token.ext,
      token.description || '',
      token.totalSupply,
    );
  } else throw new Error(`MINT DENIED: ${account.address} | ${JSON.stringify(token)}`);
}

module.exports = {
  mintERC721,
};
