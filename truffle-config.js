const HDWalletProvider = require('truffle-hdwallet-provider');
require ('dotenv').config()

module.exports = {
  contracts_directory: "./ethereum",
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    rinkeby: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 4
      // gas: 2700000,
      // gasPrice: 10000000000
    },
    matic: {
      provider: () => new HDWalletProvider(process.env.matic, `https://rpc-mainnet.matic.network`),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: false
    },
    maticTestnet: {
      provider: () => new HDWalletProvider(process.env.maticTestnet, `https://rpc-mumbai.matic.today`),
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