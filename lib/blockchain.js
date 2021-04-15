const events = require('events');
const {EventEmitter} = events;
const dns = require('dns');
const https = require('https');
const fetch = require('node-fetch');
const Web3 = require('web3');
const {timeout} = require('../lib/util.js');

const infuraProjectId = process.env.infuraProjectId;
const polygonVigilKey = process.env.polygonVigilKey;

const ethereumHost = 'ethereum.exokit.org';

let addresses,
  abis,
  web3,
  web3sockets,
  contracts,
  gethNodeUrl,
  gethNodeWSUrl;

const BlockchainNetworks = [
  "mainnet",
  "mainnetsidechain",
  //"testnet",
  "polygon",
  //"testnetpolygon",
];

const loadPromise = (async() => {
  const [
    newAddresses,
    newAbis,
    ethereumHostAddress,
    newPorts,
  ] = await Promise.all([
    fetch('https://contracts.webaverse.com/config/addresses.js').then(res => res.text()).then(s => JSON.parse(s.replace(/^\s*export\s*default\s*/, ''))),
    fetch('https://contracts.webaverse.com/config/abi.js').then(res => res.text()).then(s => JSON.parse(s.replace(/^\s*export\s*default\s*/, ''))),
    new Promise((accept, reject) => {
      dns.resolve4(ethereumHost, (err, addresses) => {
        if (!err) {
          if (addresses.length > 0) {
            accept(addresses[0]);
          } else {
            reject(new Error('no addresses resolved for ' + ethereumHost));
          }
        } else {
          reject(err);
        }
      });
    }),
    (async () => {
      return await new Promise((accept, reject) => {
        const proxyReq = https.request('https://contracts.webaverse.com/config/ports.js', proxyRes => {
          const bs = [];
          proxyRes.on('data', b => {
            bs.push(b);
          });
          proxyRes.on('end', () => {
            accept(JSON.parse(Buffer.concat(bs).toString('utf8').slice('export default'.length)));
          });
          proxyRes.on('error', err => {
            reject(err);
          });
        });
        proxyReq.end();
      });
    })(),
  ]);
  addresses = newAddresses;
  abis = newAbis;

  const ports = newPorts;
  gethNodeUrl = `http://${ethereumHostAddress}`;
  gethNodeWSUrl = `ws://${ethereumHostAddress}`;

  web3 = {
    mainnet: new Web3(new Web3.providers.HttpProvider(
      `https://mainnet.infura.io/v3/${infuraProjectId}`
    )),
    mainnetsidechain: new Web3(new Web3.providers.HttpProvider(
      `${gethNodeUrl}:${ports.mainnetsidechain}`
    )),
    polygon: new Web3(new Web3.providers.HttpProvider(
      `https://rpc-mainnet.maticvigil.com/v1/${polygonVigilKey}`
    )),
  };

  contracts = {};
  BlockchainNetworks.forEach(network => {
    contracts[network] = {
      Account: new web3[network].eth.Contract(abis.Account, addresses[network].Account),
      FT: new web3[network].eth.Contract(abis.FT, addresses[network].FT),
      FTProxy: new web3[network].eth.Contract(abis.FTProxy, addresses[network].FTProxy),
      NFT: new web3[network].eth.Contract(abis.NFT, addresses[network].NFT),
      NFTProxy: new web3[network].eth.Contract(abis.NFTProxy, addresses[network].NFTProxy),
      Trade: new web3[network].eth.Contract(abis.Trade, addresses[network].Trade),
      LAND: new web3[network].eth.Contract(abis.LAND, addresses[network].LAND),
      LANDProxy: new web3[network].eth.Contract(abis.LANDProxy, addresses[network].LANDProxy),
    }
  })
})();

async function getPastEvents({
  network,
  contractName,
  eventName = 'allEvents',
  fromBlock = 0,
  toBlock = 'latest',
} = {}) {
  try {
    const {contracts} = await getBlockchain();
    return await contracts[network][contractName].getPastEvents(
      eventName,
      {
        fromBlock,
        toBlock,
      }
    );
  } catch(e) {
    console.error(e);
    return [];
  }
}

async function getEventsRated( {
  network,
  contractName,
  eventName = 'allEvents',
  rate = 1000,
  sleep = 100,
}) {
  // Get latest block number.
  // WARNING: Minting/Transfers should be paused prior to
  // migrating tokens or changes after this moment could be lost.
  const { web3 } = await getBlockchain();
  const latestBlock = await new web3[network].eth.getBlockNumber();

  // Loop through past events at the provided rate.
  const events = [];
  let block = 0;
  let newBlock = 0;

  while (block < latestBlock) {
    newBlock = Math.min(latestBlock, block + rate)

    //if (!network)

    events.push(...(await getPastEvents({
      network,
      contractName,
      eventName,
      fromBlock: block,
      toBlock: newBlock,
    })));

    block = newBlock

    await timeout(sleep);
  }

  return events
}

async function getBlockchain() {
  await loadPromise;
  return {
    addresses,
    abis,
    web3,
    // web3socketProviders,
    web3sockets,
    contracts,
    // wsContracts,
    gethNodeUrl,
    gethNodeWSUrl,
  };
}

function isBurned(address) {
  return address === '0x0000000000000000000000000000000000000000'
}

module.exports = {
  getEventsRated,
  getPastEvents,
  getBlockchain,
  isBurned,
};
