const {runTransaction} = require('../../lib/runTransaction');
const {getPastEvents} = require('../../lib/blockchain');
const {network} = require('../../lib/const');
const {deployERC20} = require('../../lib/deploy/WebaverseERC20');
const {getTransferEvents} = require('../../lib/events');
const {replayEvents} = require('../../lib/replayEvents');
const {getTokensFromEvents} = require('../../lib/tokens');

module.exports.migrateERC20 = async function(deployer) {
  console.log(':: Migrating ERC20 tokens.');

  const events = await getPastEvents({
    network,
    contractName: 'FT',
  });

  // Get events.
  const transferEvents = getTransferEvents(events);

  // Get tokens.
  const tokens = await getTokensFromEvents(events);
  console.log(`Found ${tokens.length} ERC20 tokens.`);

  // Deploy.
  const erc20 = await deployERC20(deployer);

  // Replay events.
  /* console.log('Replaying ERC20 Transfer events...');
  await replayEvents(
    transferEvents,
    'FT',
    'transferFrom',
    ['from', 'to', 'value'],
  ); */

  return erc20;
};
