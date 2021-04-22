const deployERC721 = require('../lib/deploy/WebaverseERC721');
const {assert} = require('../lib/assert');
const {getBlockchain, getEventsRated} = require('../lib/blockchain');

const {
  network,
  signer,
  treasurer,
} = require('../lib/const');

const {
  getHashUpdateEvents,
  getMetadataSetEvents,
  getMintEvents,
  getSingleMetadataSetEvents,
} = require('../lib/events');

const {getTokenFromEvent, getTokens} = require('../lib/tokens');
const {mintToken} = require('../lib/mint');
const {replayEvents} = require('../lib/replayEvents');


const mintAddress = process.env.publicAddress;
const ERC20Address = '0xb669000Ee52F10484363bC2e1D0020535F9102EA';

//const ERC721Address = ERC721.address;

function migrateTokens({events, tokens, network}) {
  // Process tokens.
  tokens.forEach( token => {
    //const tokenEvents = getTokenEvents(token.id, events)
    //mint(token)
  })

  /*hashUpdateEvents.forEach( event => {
    const {returnValues: {oldHash, newHash}} = event;

    // call setHash with new contract address.
  })*/

}

async function checkEnvironment() {
  const {account} = await getBlockchain();

  [
    [account, `Account: ${account.address}`, 'MISSING ACCOUNT.'],
    [network, `Network: ${network}`, `MISSING NETWORK: ${process.argv[4]}`],
    [signer, `Signer: ${signer}`, 'MISSING SIGNER.'],
    [treasurer, `Treasury: ${treasurer}`, 'MISSING TREASURER.'],
  ].forEach(assert)
}

module.exports = async function (deployer) {
  await checkEnvironment();

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
  if (!mintEvents.length) throw new Error('NO MINT EVENTS FOUND.');
  if (!tokens.length) throw new Error('NO TOKENS FOUND.');

  console.log('Found tokens:', tokens.length);

  // Deploy contract.
  const erc721 = await deployERC721(deployer, {ERC20Address});

  console.log( 'Minting tokens...',  )

  // Remint tokens from mint events.
  const newMints = await Promise.all(
    mintEvents.map(async event => mintToken(
      erc721,
      getTokenFromEvent(tokens, event),
    ))
  );

  console.log('New mints:', newMints.length);

  // Replay events.
  console.log( 'Replaying HashUpdate events...');
  await replayEvents(
    hashUpdateEvents,
    'NFT',
    'updateHash',
    ['oldHash', 'newHash']
  );

  console.log( 'Replaying MetaDataSet events...');
  await replayEvents(
    metadataSetEvents,
    'NFT',
    'setMetadata',
    ['hash', 'key', 'value']
  );

  console.log( 'Replaying SingleMetadataSet events...');
  await replayEvents(
    singleMetadataSetEvents,
    'NFT',
    'setSingleMetadata',
    ['tokenId', 'key', 'value']
  );
};
