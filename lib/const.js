// NFT
const mintFee = 10;
const tokenBaseUri = "https://tokens.webaverse.com/";

const NetworkTypes = {
  "mainnet": "mainnet",
  "mainnetsidechain": "mainnetsidechain",
  "polygon": "polygon",
  "testnet": "testnet",
  "testnetsidechain": "testnetsidechain",
  "testnetpolygon": "testnetpolygon",
  "development": "development"
}

const treasurer = {
  "mainnet": process.env.mainnetTreasuryAddress,
  "mainnetsidechain": process.env.mainnetsidechainTreasuryAddress,
  "polygon": process.env.polygonTreasuryAddress,
  "testnet": process.env.testnetTreasuryAddress,
  "testnetsidechain": process.env.testnetsidechainTreasuryAddress,
  "testnetpolygon": process.env.testnetpolygonTreasuryAddress,
  "development": process.env.developmentTreasuryAddress,
}

const signer = {
  "mainnet": process.env.mainnetSignerAddress,
  "mainnetsidechain": process.env.mainnetsidechainSignerAddress,
  "polygon": process.env.polygonSignerAddress,
  "testnet": process.env.testnetSignerAddress,
  "testnetsidechain": process.env.testnetsidechainSignerAddress,
  "testnetpolygon": process.env.testnetpolygonSignerAddress,
  "development": process.env.developmentSignerAddress,
}

module.exports = {
  mintFee,
  NetworkTypes,
  tokenBaseUri,
  treasurer,
  signer
}
