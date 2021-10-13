require("@nomiclabs/hardhat-waffle");

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {},
        // rinkeby: {
        //   url: "https://eth-mainnet.alchemyapi.io/v2/123abc123abc123abc123abc123abcde",
        //   accounts: [privateKey1, privateKey2, ...]
        // }
    },
    solidity: {
        version: "0.8.0",
        // settings: {
        //     optimizer: {
        //         enabled: true,
        //         runs: 200,
        //     },
        // },
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./build",
    },
    mocha: {
        timeout: 20000,
    },
};
