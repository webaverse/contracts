const ERC20 = artifacts.require('WebaverseERC20');
const ERC721 = artifacts.require('WebaverseERC721');
const deployERC721 = require('../lib/deploy/WebaverseERC721.js');

const {getEventsRated} = require('../lib/blockchain.js');
const {getTokens} = require('../lib/tokens.js');

const {network, signer, treasurer} = require('../lib/const.js');

const mintAddress = process.env.publicAddress;
const nonceAddress= mintAddress;
const gas = 500000;

const ERC721Address = ERC721.address;

function migrateTokens({events, tokens, network}) {
  // Process tokens.
  tokens.forEach( token => {
    //const tokenEvents = getTokenEvents(token.id, events)
    //mint(token)
  })

  // Replay HashUpdate events.
  const hashUpdateEvents = events.filter(e => e.event === 'HashUpdate');

  hashUpdateEvents.forEach( event => {
    const {returnValues: {oldHash, newHash}} = event;



    // call setHash with new contract address.
  })

}

module.exports = async function (deployer) {
  // Validate
  if (!network) return console.error('INVALID NETWORK:', process.argv[4]);
  else console.log('NETWORK:', network);

  if (!signer) return console.error('INVALID SIGNER.');
  else console.log('SIGNER:', signer);

  if (!treasurer) return console.error('INVALID TREASURER.');
  else console.log("Treasury is", treasurer);

  // Enumerate events and tokens.
  const events = await getEventsRated({
    network,
    contractName: 'NFT',
    rate: 10000,
    sleep: 0,
  });

  const tokens = await getTokens({events, network});

  if (tokens.length > 0) {
    migrateTokens({events, tokens, network});
  } else {
    throw new Error('No tokens found.')
  }

  // Deploy
  const erc721 = await deployERC721(deployer);
  const newAddress = erc721.address;

  // Remint

  // Get events.

    // Look up minter address.
    // Remint with... treasury address?
};
