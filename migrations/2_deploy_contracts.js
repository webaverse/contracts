const Account = artifacts.require("WebaverseAccount");
const ERC20 = artifacts.require("WebaverseERC20");
const ERC20Proxy = artifacts.require("WebaverseERC20Proxy");
const ERC721 = artifacts.require("WebaverseERC721");
const ERC721Proxy = artifacts.require("WebaverseERC721Proxy");
const Trade = artifacts.require("WebaverseTrade");

const addresses = require("../config/addresses.js");
const signer = require("../config/signer.js");
const treasurer = require("../config/treasurer.js");

const chainId = require("../config/chain-id.js");

// Important vars
const BaseURI = "???";

// FT
const ERC20ContractName = "FT";
const ERC20Symbol = "SILK";
const ERC20MarketCap = 2147483648000000000000000000;

// NFTs
const ERC721TokenContractName = "NFT";
const ERC721TokenContractSymbol = "NFT";
const tokenIsSingleIssue = false;
const tokenIsPublicallyMintable = true;
const mintFee = 10;

// LAND
const ERC721LandContractName = "LAND";
const ERC721LandContractSymbol = "LAND";
const landIsSingleIssue = true;
const landIsPublicallyMintable = false;

const NetworkTypes = {
  "mainnet": "mainnet",
  "mainnetsidechain": "mainnetsidechain",
  "rinkeby": "rinkeby",
  "mainnetsidechain": "mainnetsidechain",
  "maticTestnet": "maticTestnet",
  "matic": "matic"
}

module.exports = function (deployer) {
  const networkType = NetworkTypes[process.argv[4]];

  if (!networkType) 
    return console.error(process.argv[4] + " was not found in the network list");

  if(!signer[networkType])
    return console.error("Signer address not valid");

  if(!treasurer[networkType])
    return console.error("Treasury address not valid");

  console.log("Deploying on the " + networkType + " network. Addresses are:");
  console.log(addresses);

  deployer.deploy(Account)
    .then(() => {
      console.log("Account address is " + Account.address)
      deployer.deploy(ERC20, ERC20ContractName, ERC20Symbol, ERC20MarketCap).then(() => {
        console.log("ERC20 address is " + ERC20.address);

        /** parentAddress, signerAddress, _chainId */
        console.log("Deployed ERC20Proxy with values", ERC20Proxy, ERC20.address, signer[network], chainId[networkType][ERC20ContractName])
        deployer.deploy(ERC20Proxy, ERC20.address, signer[network], chainId[networkType][ERC20ContractName])
          .then(() => {
          console.log("ERC20 address is " + ERC20Proxy.address);

          /** name, symbol, baseUri, _erc20Contract, _mintFee, _treasuryAddress, _isSingleIssue, _isPublicallyMintable */
          deployer.deploy(ERC721, ERC721TokenContractName, ERC721TokenContractSymbol, ERC20Proxy.address, mintFee, treasurer[networkType], tokenIsSingleIssue, tokenIsPublicallyMintable)
          .then(() => {
            console.log("ERC721 Token address is " + ERC721.address);

            /** name, symbol, baseUri, _erc20Contract, _mintFee, _treasuryAddress, _isSingleIssue, _isPublicallyMintable */
            deployer.deploy(ERC721, ERC721LandContractName, ERC721LandContractSymbol, ERC20Proxy.address, mintFee, treasurer[networkType], landIsSingleIssue, landIsPublicallyMintable)
            .then(() => {
              console.log("ERC721 LAND address is " + ERC721.address);

              /** parentAddress, signerAddress, _chainId */
              deployer.deploy(ERC721Proxy, RC721.address, signer[network], chainId[networkType][ERC20ContractName])
              .then(() => {
                console.log("ERC721Proxy address is " + ERC721Proxy.address);

                /** parentERC20Address, parentERC721Address, signerAddress */
                deployer.deploy(Trade, ERC20.address, ERC721.address, signer[network]).then(() => {
                  console.log("Trade address is " + Trade.address);
                })
              })
            })
          })
        })
      })
    })
};
