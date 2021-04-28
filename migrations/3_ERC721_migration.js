const {migrateERC20} = require('./3_ERC721_migration/migrateERC20');
const {migrateERC721} = require('./3_ERC721_migration/migrateERC721');
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
  const erc721 = await migrateERC721(deployer, erc20);
};
