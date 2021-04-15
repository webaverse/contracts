const ERC20 = artifacts.require("WebaverseERC20");
const ERC721 = artifacts.require("WebaverseERC721");

const {mintFee, network, tokenBaseUri, treasurer} = require('../const.js');

const ERC20Address = ERC20.address;
const ERC721TokenContractName = 'ASSET';
const ERC721TokenContractSymbol = 'ASSET';
const tokenIsSingleIssue = false;
const tokenIsPubliclyMintable = true;

async function deployERC721 (deployer) {
  const ERC721Fields = [
    ERC721TokenContractName,
    ERC721TokenContractSymbol,
    tokenBaseUri,
    ERC20Address,
    mintFee,
    treasurer[network],
    tokenIsSingleIssue,
    tokenIsPubliclyMintable,
  ]

  console.log('Attempting to deploy ERC721 contract:');
  console.log(...ERC721Fields);

  await deployer.deploy(...ERC721Fields);

  let erc721 = await ERC721.deployed();

  console.log("WebaverseERC721 token address:" + erc721.address);

  return erc721;
}

module.exports = deployERC721;
