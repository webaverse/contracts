const HDWalletProvider = require('truffle-hdwallet-provider');
require('dotenv').config()

module.exports = {
  contracts_directory: "./ethereum",
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    rinkeby: {
      host: "localhost",
      provider: () => new HDWalletProvider(process.env.rinkeby, "https://rinkeby.infura.io/v3/" + process.env.INFURA_API_KEY),
      network_id: 4,
      gas: 6700000,
      gasPrice: 10000000000
    },
    webaverse: {
      host: "127.0.0.1",
      // provider: () => new HDWalletProvider(process.env.webaverse, "http://ethereum.exokit.org"),
      port: 1337,
      network_id: 4,
      gas: 6700000,
      gasPrice: 10000000000
    },
    webaverseTestnet: {
      host: "127.0.0.1",
      // provider: () => new HDWalletProvider(process.env.webaverse, "http://ethereum.exokit.org"),
      port: 1338,
      network_id: 4,
      gas: 6700000,
      gasPrice: 10000000000
    },
    polygon: {
      provider: () => new HDWalletProvider(process.env.polygon, `https://rpc-mainnet.polygon.network`),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: false
    },
    polygonTestnet: {
      provider: () => new HDWalletProvider(process.env.polygonTestnet, `https://rpc-mumbai.polygon.today`),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "^0.6.2",
      settings: {
        optimizer: {
          enabled: true,
          runs: 1500
        }
      }
    }
  }
}
