const chainIds = require("../config/chainIds.js");
const providers = require('./providers');

const infuraProjectId = process.env.infuraProjectId;
const polygonVigilKey = process.env.polygonVigilKey;

const signers = {
  "development": process.env.developmentSignerAddress,
  "mainnet": process.env.mainnetSignerAddress,
  "mainnetsidechain": process.env.mainnetsidechainSignerAddress,
  "polygon": process.env.polygonSignerAddress,
  "testnet": process.env.testnetSignerAddress,
  "testnetsidechain": process.env.testnetsidechainSignerAddress,
  "testnetpolygon": process.env.testnetpolygonSignerAddress
}

const treasurers = {
  "development": process.env.developmentTreasuryAddress,
  "mainnet": process.env.mainnetTreasuryAddress,
  "mainnetsidechain": process.env.mainnetsidechainTreasuryAddress,
  "polygon": process.env.polygonTreasuryAddress,
  "testnet": process.env.testnetTreasuryAddress,
  "testnetsidechain": process.env.testnetsidechainTreasuryAddress,
  "testnetpolygon": process.env.testnetpolygonTreasuryAddress
}

const networkTypes = {
  "mainnet": "mainnet",
  "mainnetsidechain": "mainnetsidechain",
  "polygon": "polygon",
  "testnet": "testnet",
  "testnetsidechain": "testnetsidechain",
  "testnetpolygon": "testnetpolygon",
  "development": "development"
}

const network = networkTypes[process.argv[4]];
const chainId = chainIds[network];
const provider = providers[network];
const signer = signers[network];
const treasurer = treasurers[network];

const mintFee = 10;
const ethereumHost = 'ethereum.exokit.org';
const storageHost = 'https://ipfs.exokit.org';
const tokenBaseUri = "https://tokens.webaverse.com/";
const zeroAddress = '0x0000000000000000000000000000000000000000'

module.exports = {
  infuraProjectId,
  polygonVigilKey,
  network,
  chainId,
  provider,
  signer,
  treasurer,
  mintFee,
  ethereumHost,
  storageHost,
  tokenBaseUri,
  zeroAddress,
};
