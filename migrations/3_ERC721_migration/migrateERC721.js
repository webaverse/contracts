const {getEventsRated} = require('../../lib/blockchain');
const {network} = require('../../lib/const');
const deployERC721 = require('../../lib/deploy/WebaverseERC721');

const {
  getHashUpdateEvents,
  getMetadataSetEvents,
  getMintEvents,
  getSingleMetadataSetEvents,
} = require('../../lib/events');

const {mintToken} = require('../../lib/mint');
const {replayEvents} = require('../../lib/replayEvents');
const {getTokenFromEvent, getTokens} = require('../../lib/tokens');

module.exports.migrateERC721 = async function(deployer, erc20) {
  console.log(':: Migrating ERC721 tokens.');

  const events = await getEventsRated({
    network,
    contractName: 'NFT',
    rate: 100000,
    sleep: 0,
  });

  // Get events.
  const hashUpdateEvents = getHashUpdateEvents(events);
  const metadataSetEvents = getMetadataSetEvents(events);
  const singleMetadataSetEvents = getSingleMetadataSetEvents(events);
  const mintEvents = getMintEvents(events);

  // Get tokens.
  const tokens = await getTokens(events);

  // Validate results.
  if (!mintEvents.length) throw new Error('ERC721: NO MINT EVENTS FOUND.');
  if (!tokens.length) throw new Error('ERC721: NO TOKENS FOUND.');

  console.log(`Found ${tokens.length} ERC721 tokens.`);

  // Deploy contract.
  const erc721 = await deployERC721(deployer, {erc20});

  console.log('Reminting tokens...');

  // Remint tokens from mint events.
  const newMints = await Promise.all(
    mintEvents.map(async event => mintToken(
      erc721,
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
  );

  return {contract: erc721};
};
