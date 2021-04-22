const Account = artifacts.require("WebaverseAccount");
const ERC20 = artifacts.require("WebaverseERC20");
const ERC20Proxy = artifacts.require("WebaverseERC20Proxy");
const ERC721 = artifacts.require("WebaverseERC721");
const ERC721Proxy = artifacts.require("WebaverseERC721Proxy");
const ERC721LAND = artifacts.require("WebaverseERC721");
const ERC721LANDProxy = artifacts.require("WebaverseERC721Proxy");
const Trade = artifacts.require("WebaverseTrade");

const chainIds = require("../config/chainIds.js");

const {
  mintFee,
  network,
  tokenBaseUri,
  treasurer,
  signer,
} = require('../lib/const');

// FT
const ERC20ContractName = "SILK";
const ERC20Symbol = "SILK";
const ERC20MarketCap = "2147483648000000000000000000";

// NFTs
const ERC721TokenContractName = "ASSET";
const ERC721TokenContractSymbol = "ASSET";
const tokenIsSingleIssue = false;
const tokenIsPublicallyMintable = true;

// LAND
const ERC721LandContractName = "LAND";
const ERC721LandContractSymbol = "LAND";
const landIsSingleIssue = true;
const landIsPublicallyMintable = false;
const landBaseUri = "https://land.webaverse.com/";

module.exports = async function (deployer) {
  if (!network)
    return console.error(process.argv[4] + " was not found in the network list");


  if (!signer)
    return console.error("Signer address not valid");

  console.log("Treasury is", treasurer);

  if (!treasurer)
    return console.error("Treasury address not valid");

  console.log("Deploying on the " + network + " network");
  await deployer.deploy(Account)
  let account = await Account.deployed()
  console.log("Account address is " + account.address)

  await deployer.deploy(ERC20, ERC20ContractName, ERC20Symbol, 10)
  let erc20 = await ERC20.deployed()
  const ERC20Address = erc20.address;

  console.log("ERC20 address is " + ERC20Address);
  /** parentAddress, signerAddress, _chainId */
  await deployer.deploy(ERC20Proxy, ERC20Address, signer, chainIds[network][ERC20ContractName])
  let erc20Proxy = await ERC20Proxy.deployed()
  const ERC20ProxyAddress = erc20Proxy.address;

  console.log("ERC20Proxy address is " + ERC20ProxyAddress);

  console.log("Attempting to deploy ERC721 contract with these variables")
  console.log(ERC721TokenContractName,
    ERC721TokenContractSymbol,
    tokenBaseUri,
    ERC20Address,
    mintFee,
    treasurer,
    tokenIsSingleIssue,
    tokenIsPublicallyMintable)
  /** name, symbol, baseUri, _erc20Contract, _mintFee, _treasuryAddress, _isSingleIssue, _isPublicallyMintable */
  await deployer.deploy(ERC721,
    ERC721TokenContractName,
    ERC721TokenContractSymbol,
    tokenBaseUri,
    ERC20Address,
    mintFee,
    treasurer,
    tokenIsSingleIssue,
    tokenIsPublicallyMintable)

  let erc721 = await ERC721.deployed()
  const ERC721Address = erc721.address;

  console.log("ERC721 Token address is " + ERC721Address);

  /** parentAddress, signerAddress, _chainId */
  await deployer.deploy(ERC721Proxy, ERC721Address, signer, chainIds[network][ERC721TokenContractName])
  let erc721Proxy = await ERC721Proxy.deployed()

  const ERC721ProxyAddress = erc721Proxy.address;

  console.log("ERC721Proxy address is " + ERC721ProxyAddress);

  /** name, symbol, baseUri, _erc20Contract, _mintFee, _treasuryAddress, _isSingleIssue, _isPublicallyMintable */
  await deployer.deploy(
    ERC721LAND,
    ERC721LandContractName,
    ERC721LandContractSymbol,
    landBaseUri,
    ERC20Address,
    mintFee,
    treasurer,
    landIsSingleIssue,
    landIsPublicallyMintable)

    let erc721LAND = await ERC721LAND.deployed()

  console.log("ERC721 LAND address is " + erc721LAND.address);
  const ERC721LANDAddress = erc721LAND.address;
  /** parentAddress, signerAddress, _chainId */
  await deployer.deploy(ERC721LANDProxy, ERC721LANDAddress, signer, chainIds[network][ERC721LandContractName])

  console.log("ERC721LANDProxy address is " + ERC721LANDProxy.address);

  /** parentERC20Address, parentERC721Address, signerAddress */
  await deployer.deploy(Trade, ERC20Address, ERC721Address, signer)
  let trade = await Trade.deployed()
  console.log("Trade address is " + trade.address);

  console.log("*******************************")
  console.log("Signer: ", signer);
  console.log("Treasury: ", treasurer);
  console.log("Deploying on the " + network + " network.");
  console.log("*******************************")
  console.log("\"" + network + "\": {");
  console.log(" \"Account\": " + "\"" + account.address + "\",")
  console.log(" \"FT\": " + "\"" + ERC20Address + "\",");
  console.log(" \"FTProxy\": " + "\"" + ERC20ProxyAddress + "\",");
  console.log(" \"NFT\": " + "\"" + ERC721Address + "\",");
  console.log(" \"NFTProxy\": " + "\"" + ERC721ProxyAddress + "\",");
  console.log(" \"LAND\": " + "\"" + ERC721LANDAddress + "\",");
  console.log(" \"LANDProxy\": " + "\"" + ERC721LANDProxy.address + "\",");
  console.log("}");
  console.log("*******************************")
};
