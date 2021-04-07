const ERC20 = artifacts.require("WebaverseERC20");
const ERC721 = artifacts.require("WebaverseERC721");

const {
  mintFee,
  NetworkTypes,
  tokenBaseUri,
  treasurer,
  signer
} = require('../lib/const.js');

const ERC20Address = ERC20.address;
const ERC721TokenContractName = "ASSET";
const ERC721TokenContractSymbol = "ASSET";
const tokenIsSingleIssue = false;
const tokenIsPublicallyMintable = true;

const networkType = NetworkTypes[process.argv[4]];

async function deployERC721 (deployer) {
  console.log("Attempting to deploy ERC721 contract with these variables");

  console.log(
    ERC721TokenContractName,
    ERC721TokenContractSymbol,
    tokenBaseUri,
    ERC20Address,
    mintFee,
    treasurer[networkType],
    tokenIsSingleIssue,
    tokenIsPublicallyMintable
  );
  
  await deployer.deploy(
    ERC721,
    ERC721TokenContractName,
    ERC721TokenContractSymbol,
    tokenBaseUri,
    ERC20Address,
    mintFee,
    treasurer[networkType],
    tokenIsSingleIssue,
    tokenIsPublicallyMintable
  );

  let erc721 = await ERC721.deployed();
  const ERC721Address = erc721.address;

  console.log("ERC721 Token address is " + ERC721Address);

  return erc721;
}

module.exports = async function (deployer) {
  // Validate
  if (!networkType)
    return console.error(process.argv[4] + " was not found in the networkType list.");

  console.log("Signer is", signer[networkType]);

  if (!signer[networkType])
    return console.error("Signer address not valid.");

  console.log("Treasury is", treasurer[networkType]);

  if (!treasurer[networkType])
    return console.error("Treasury address not valid.");

  // Deploy
  const erc721 = await deployERC721(deployer);  
};
