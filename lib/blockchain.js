const dns = require('dns');
const https = require('https');
const fetch = require('node-fetch');
const Web3 = require('web3');

const {
  ethereumHost,
  infuraProjectId,
  network,
  networks,
  polygonVigilKey,
  zeroAddress,
} = require('../lib/const');

const {timeout} = require('../lib/util');

// Used for function parameter defaults.
const net = network;

let
  account,
  addresses,
  abis,
  web3,
  web3s,
  contracts,
  gasPrice,
  gethNodeUrl,
  gethNodeWSUrl;

const loadPromise = (async () => {
  const [
    newAddresses,
    newAbis,
    ethereumHostAddress,
    newPorts,
  ] = await Promise.all([
    // newAddresses
    fetch('https://contracts.webaverse.com/config/addresses.js').then(res => res.text()).then(s => JSON.parse(s.replace(/^\s*export\s*default\s*/, ''))),

    // newAbis
    fetch('https://contracts.webaverse.com/config/abi.js').then(res => res.text()).then(s => JSON.parse(s.replace(/^\s*export\s*default\s*/, ''))),

    // ethereumHostAddress
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

    // newPorts
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

  web3s = {
    development: new Web3(new Web3.providers.HttpProvider(
      'http://127.0.0.1:7545',
    )),
    mainnet: new Web3(new Web3.providers.HttpProvider(
      `https://mainnet.infura.io/v3/${infuraProjectId}`,
    )),
    mainnetsidechain: new Web3(new Web3.providers.HttpProvider(
      `${gethNodeUrl}:${ports.mainnetsidechain}`,
    )),
    polygon: new Web3(new Web3.providers.HttpProvider(
      `https://rpc-mainnet.maticvigil.com/v1/${polygonVigilKey}`,
    )),
  };

  web3 = web3s[network];
  gasPrice = parseInt(await web3.eth.getGasPrice(), 10);
  account = web3.eth.accounts.privateKeyToAccount(process.env[network]);

  contracts = {};

  networks.forEach(n => {
    contracts[n] = {
      Account: new web3s[n].eth.Contract(abis.Account, addresses[n].Account),
      FT: new web3s[n].eth.Contract(abis.FT, addresses[n].FT),
      FTProxy: new web3s[n].eth.Contract(abis.FTProxy, addresses[n].FTProxy),
      NFT: new web3s[n].eth.Contract(abis.NFT, addresses[n].NFT),
      NFTProxy: new web3s[n].eth.Contract(abis.NFTProxy, addresses[n].NFTProxy),
      Trade: new web3s[n].eth.Contract(abis.Trade, addresses[n].Trade),
      LAND: new web3s[n].eth.Contract(abis.LAND, addresses[n].LAND),
      LANDProxy: new web3s[n].eth.Contract(abis.LANDProxy, addresses[n].LANDProxy),
    };
  });
})();

async function getBlockchain() {
  await loadPromise;
  return {
    account,
    addresses,
    abis,
    web3,
    web3s,
    contracts,
    gasPrice,
    gethNodeUrl,
    gethNodeWSUrl,
  };
}

async function getEventsRated({
  network,
  contractName,
  eventName = 'allEvents',
  rate = 1000,
  sleep = 100,
}) {
  // Get latest block number.
  // WARNING: Minting/Transfers should be paused prior to
  // migrating tokens or changes after this moment could be lost.
  const {web3} = await getBlockchain();
  const latestBlock = await new web3.eth.getBlockNumber();

  // Loop through past events at the provided rate.
  const events = [];
  let block = 0;
  let newBlock = 0;

  while (block < latestBlock) {
    newBlock = Math.min(latestBlock, block + rate);

    // if (!network)

    events.push(...(await getPastEvents({
      network,
      contractName,
      eventName,
      fromBlock: block,
      toBlock: newBlock,
    })));

    block = newBlock;
    await timeout(sleep);
  }

  return events;
}

async function getNonce() {
  const {account: {address}, web3} = await getBlockchain();
  return web3.eth.getTransactionCount(address);
}

async function getPastEvents({
  network = net,
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
      },
    );
  } catch (e) {
    console.error(e);
    return [];
  }
}

function isBurned(address) {
  return address === zeroAddress;
}

module.exports = {
  getBlockchain,
  getEventsRated,
  getNonce,
  getPastEvents,
  isBurned,
};
