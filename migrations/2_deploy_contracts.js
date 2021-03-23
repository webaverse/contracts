const Account = artifacts.require("WebaverseAccount");
const ERC20 = artifacts.require("WebaverseERC20");
const ERC20Proxy = artifacts.require("WebaverseERC20Proxy");
const ERC721 = artifacts.require("WebaverseERC721");
const ERC721Proxy = artifacts.require("WebaverseERC721Proxy");
const ERC721LAND = artifacts.require("WebaverseERC721");
const ERC721LANDProxy = artifacts.require("WebaverseERC721Proxy");
const Trade = artifacts.require("WebaverseTrade");

const signer = require("../config/signer.js");
const treasurer = require("../config/treasurer.js");

const chainId = require("../config/chainIds.js");

// Important vars
const baseURI = "???";

// FT
const ERC20ContractName = "FT";
const ERC20Symbol = "SILK";
const ERC20MarketCap = "2147483648000000000000000000";

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

module.exports = async function (deployer) {
  const networkType = NetworkTypes[process.argv[4]];

  if (!networkType)
    return console.error(process.argv[4] + " was not found in the networkType list");

  console.log("Signer is", signer[networkType]);

  if (!signer[networkType])
    return console.error("Signer address not valid");

  console.log("Treasury is", treasurer[networkType]);

  if (!treasurer[networkType])
    return console.error("Treasury address not valid");

  console.log("Deploying on the " + networkType + " networkType");

  await deployer.deploy(Account)
  const accountInstance = await Account.new()
  console.log("Account address is " + accountInstance.address)
  console.log(ERC20ContractName, ERC20Symbol, ERC20MarketCap);
  await deployer.deploy(ERC20, ERC20ContractName, ERC20Symbol, 10)

  console.log("ERC20 address is " + ERC20.address);

  /** parentAddress, signerAddress, _chainId */
  console.log("Deployed ERC20Proxy with values", ERC20Proxy, ERC20.address, signer[networkType], chainId[networkType][ERC20ContractName])
  await deployer.deploy(ERC20Proxy, ERC20.address, signer[networkType], chainId[networkType][ERC20ContractName])
  console.log("ERC20 address is " + ERC20Proxy.address);

  /** name, symbol, baseUri, _erc20Contract, _mintFee, _treasuryAddress, _isSingleIssue, _isPublicallyMintable */
  await deployer.deploy(
    ERC721,
    ERC721TokenContractName,
    ERC721TokenContractSymbol,
    baseURI,
    ERC20Proxy.address,
    mintFee,
    treasurer[networkType],
    tokenIsSingleIssue,
    tokenIsPublicallyMintable)
  console.log("ERC721 Token address is " + ERC721.address);

  /** parentAddress, signerAddress, _chainId */
  await deployer.deploy(ERC721Proxy, RC721.address, signer[networkType], chainId[networkType][ERC721TokenContractName])
  console.log("ERC721Proxy address is " + ERC721Proxy.address);

  /** name, symbol, baseUri, _erc20Contract, _mintFee, _treasuryAddress, _isSingleIssue, _isPublicallyMintable */
  await deployer.deploy(
    ERC721LAND,
    ERC721LandContractName,
    ERC721LandContractSymbol,
    baseURI,
    ERC20Proxy.address,
    mintFee,
    treasurer[networkType],
    landIsSingleIssue,
    landIsPublicallyMintable)
  console.log("ERC721 LAND address is " + ERC721LAND.address);

  /** parentAddress, signerAddress, _chainId */
  await deployer.deploy(ERC721LANDProxy, RC721.address, signer[networkType], chainId[networkType][ERC721LandContractName])
  console.log("ERC721Proxy LAND address is " + ERC721LANDProxy.address);

  /** parentERC20Address, parentERC721Address, signerAddress */
  await deployer.deploy(Trade, ERC20.address, ERC721.address, signer[networkType])
  console.log("Trade address is " + Trade.address);
};
