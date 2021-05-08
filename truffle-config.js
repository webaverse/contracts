const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config();

module.exports = {
  contracts_directory: './ethereum',
  networks: {
    development: {
      host: '127.0.0.1', // Localhost (default: none)
      port: 7545, // Standard Ethereum port (default: none)
      network_id: '*', // Any network (default: none)
    },
    testnet: {
      host: 'localhost',
      provider: () => new HDWalletProvider(process.env.testnet, 'https://rinkeby.infura.io/v3/' + process.env.infuraProjectId),
      network_id: 4,
      gas: 6700000,
      gasPrice: 10000000000,
    },
    testnetsidechain: {
      host: 'testnetsidechain.exokit.org',
      provider: () => new HDWalletProvider(process.env.mainnetsidechain, 'http://testnetsidechain.exokit.org'),
      port: 8486,
      network_id: '1337',
    },
    testnetpolygon: {
      provider: () => new HDWalletProvider(process.env.testnetpolygon, 'https://rpc-mumbai.matic.today'),
      network_id: 80001,
      confirmations: 1,
      timeoutBlocks: 500,
      networkCheckTimeout: 20000,
      skipDryRun: true,
    },
    mainnet: {
      // TODO: ADD ME
    },
    mainnetsidechain: {
      host: 'mainnetsidechain.exokit.org',
      provider: () => new HDWalletProvider(process.env.mainnetsidechain, 'http://mainnetsidechain.exokit.org'),
      port: 8485,
      network_id: '1338',
      networkCheckTimeout: 10000,
      gas: '5000000',
      gasPrice: '0',
    },
    polygon: {
      provider: () => new HDWalletProvider(
        process.env.polygon,
        // 'https://rpc-mainnet.maticvigil.com/',
        `https://rpc-mainnet.maticvigil.com/v1/${process.env.polygonVigilKey}`,
        // `https://rpc-webaverse-mainnet.maticvigil.com/v1/${process.env.polygonVigilKey}`
      ),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      networkCheckTimeout: 10000,
      skipDryRun: false,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure compilers.
  compilers: {
    solc: {
      version: '^0.6.2',
      settings: {
        optimizer: {
          enabled: true,
          runs: 1500,
        },
      },
    },
  },
};
