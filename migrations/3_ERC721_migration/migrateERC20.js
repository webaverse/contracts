const {getEventsRated} = require('../../lib/blockchain');
const {network} = require('../../lib/const');
const {filterUnique} = require('../../lib/util');
const {deployERC20} = require('../../lib/deploy/WebaverseERC20');

const {
  getApprovalEvents,
  getTransferEvents,
} = require('../../lib/events');

const {mintToken} = require('../../lib/mint');
const {replayEvents} = require('../../lib/replayEvents');
const {getTokenFromEvent, getTokens} = require('../../lib/tokens');

module.exports.migrateERC20 = async function(deployer) {
  console.log(':: Migrating ERC20 tokens.');

  const events = await getEventsRated({
    network,
    contractName: 'FT',
    rate: 100000,
    sleep: 0,
  });

  const transferEvents = getTransferEvents(events);
  const approvalEvents = getApprovalEvents(events);

  const erc20 = await deployERC20(deployer);

  return erc20;

  /* // Get events.
  const hashUpdateEvents = getHashUpdateEvents(events);
  const metadataSetEvents = getMetadataSetEvents(events);
  const singleMetadataSetEvents = getSingleMetadataSetEvents(events);
  const mintEvents = getMintEvents(events);

  // Get tokens.
  const tokens = await getTokens(events);

  // Validate results.
  if (!mintEvents.length) throw new Error('ERC20: NO MINT EVENTS FOUND.');
  if (!tokens.length) throw new Error('ERC20: NO TOKENS FOUND.');

  console.log(`Found ${tokens.length} ERC20 tokens.`);

  // Deploy contract.
  const erc20 = await deployERC20(deployer);

  console.log('Reminting tokens...');

  // Remint tokens from mint events.
  const newMints = await Promise.all(
    mintEvents.map(async event => mintToken(
      erc20,
      getTokenFromEvent(tokens, event),
    )),
  );

  console.log('New mints:', newMints.length);

  // Replay events.
  console.log('Replaying HashUpdate events...');
  await replayEvents(
    hashUpdateEvents,
    'NFT',
    'updateHash',
    ['oldHash', 'newHash'],
  );

  console.log('Replaying MetaDataSet events...');
  await replayEvents(
    metadataSetEvents,
    'NFT',
    'setMetadata',
    ['hash', 'key', 'value'],
  );

  console.log('Replaying SingleMetadataSet events...');
  await replayEvents(
    singleMetadataSetEvents,
    'NFT',
    'setSingleMetadata',
    ['tokenId', 'key', 'value'],
  ); */
};
