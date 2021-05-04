const {migrateERC20} = require('./3_ERC721_migration/migrateERC20');
const {migrateERC20Proxy} = require('./3_ERC721_migration/migrateERC20Proxy');
const {migrateERC721} = require('./3_ERC721_migration/migrateERC721');
const {migrateERC721Proxy} = require('./3_ERC721_migration/migrateERC721Proxy');
const {migrateTrade} = require('./3_ERC721_migration/migrateTrade');
const {assert} = require('../lib/assert');
const {getBlockchain} = require('../lib/blockchain');

const {network, signer, treasurer} = require('../lib/const');

async function checkEnvironment() {
  const {account} = await getBlockchain();
  [
    [account, `Account: ${account.address}`, 'MISSING ACCOUNT.'],
    [network, `Network: ${network}`, `MISSING NETWORK: ${process.argv[4]}`],
    [signer, `Signer: ${signer}`, 'MISSING SIGNER.'],
    [treasurer, `Treasury: ${treasurer}`, 'MISSING TREASURER.'],
  ].forEach(assert);
}

module.exports = async function(deployer) {
  await checkEnvironment();

  const erc20 = await migrateERC20(deployer);
  const erc20Proxy = await migrateERC20Proxy(erc20);

  const erc721 = await migrateERC721(deployer, {erc20});
  const erc721Proxy = await migrateERC721Proxy(erc721);

  const trade = await migrateTrade(deployer, {erc20, erc721});

  console.log('*******************************');
  console.log('Deployed on ' + network);
  console.log('*******************************');
  console.log(`"${network}": {`);
  console.log(`"FT": "${erc20.address}",`);
  console.log(`"NFT": "${erc721.address}",`);
  console.log('}');
  console.log('*******************************');
};
