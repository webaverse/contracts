const HDWalletProvider = require('@truffle/hdwallet-provider');
const {infuraProjectId, polygonVigilKey} = require('./const');

module.exports = {
  /*testnet: new HDWalletProvider(
    process.env.testnet,
    `https://rinkeby.infura.io/v3/${infuraProjectId}`,
  ),*/

  testnetpolygon: new HDWalletProvider(
    process.env.testnetpolygon,
    `https://rpc-mumbai.matic.today`,
  ),

  /*mainnet: new HDWalletProvider(
    process.env.mainnet,
    `https://mainnet.infura.io/v3/${infuraProjectId}`,
  ),*/

  mainnetsidechain: new HDWalletProvider(
    process.env.mainnetsidechain,
    "http://mainnetsidechain.exokit.org",
  ),

  polygon: new HDWalletProvider(
    process.env.polygon,
    `https://rpc-mainnet.maticvigil.com/`,
    //`https://rpc-webaverse-mainnet.maticvigil.com/v1/${polygonVigilKey}`
  ),
}
