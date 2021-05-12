const {getStuckTokenEntries, resubmitEntries} = require('../../lib/tokens');
const {getPastEvents} = require('../../lib/blockchain');
const {network} = require('../../lib/const');
const {deployERC721} = require('../../lib/deploy/WebaverseERC721');

const {
  getHashUpdateEvents,
  getMetadataSetEvents,
  getMintEvents,
  getSingleMetadataSetEvents,
} = require('../../lib/events');

const {mintERC721} = require('../../lib/mint');
const {replayEvents} = require('../../lib/replayEvents');
const {getTokenFromEvent, getTokensFromEvents} = require('../../lib/tokens');

module.exports.migrateERC721 = async function(deployer, {erc20}) {
  console.log(':: Migrating ERC721 tokens.');

  const events = await getPastEvents({
    network,
    contractName: 'NFT',
  });

  // Get events.
  const hashUpdateEvents = getHashUpdateEvents(events);
  const metadataSetEvents = getMetadataSetEvents(events);
  const singleMetadataSetEvents = getSingleMetadataSetEvents(events);
  const mintEvents = getMintEvents(events);

  // Get tokens.
  const tokens = await getTokensFromEvents(events);

  // Validate results.
  if (!mintEvents.length) throw new Error('ERC721: NO MINT EVENTS FOUND.');
  if (!tokens.length) throw new Error('ERC721: NO TOKENS FOUND.');

  console.log(`Found ${tokens.length} ERC721 tokens.`);

  // Deploy contract.
  const erc721 = await deployERC721(deployer, {erc20});

  console.log('Reminting tokens...');

  // Remint tokens from mint events.
  /*const newMints = await Promise.all(
    mintEvents.map(async event => mintERC721(
      erc721,
      getTokenFromEvent(tokens, event),
    )),
  );

  console.log('New mints:', newMints.length);*/

  /* // Replay events.
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

  // Play events in order.
  /* console.log('Replaying Deposit events...');
  await replayEvents(
    depositedEvents,
    'NFTProxy',
    'deposit',
    ['to', 'tokenId'],
  ); */

  /* console.log('Replaying Withdrew events...');
  await replayEvents(
    withdrewEvents,
    'NFTProxy',
    'withdraw',
    ['from', 'tokenId', 'timestamp'],
  ); */

  // Either withdraw on the other end

  // Or contact API server to get deposit signature

  // Check for dangling withdraw/deposits

  console.log('Getting stuck ERC721 tokens.');

  await resubmitEntries(await getStuckTokenEntries('NFT'));

  /* Handle cross-chain events. */
  // depositERC721;

  // Deposit to contract address.

  // Transfer to correct owner.

  return erc721;
};
