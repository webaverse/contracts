const ERC721 = artifacts.require("WebaverseERC721");

const {mintFee, tokenBaseUri, treasurer} = require('../const');

const ERC721TokenContractName = 'ASSET';
const ERC721TokenContractSymbol = 'ASSET';
const tokenIsSingleIssue = false;
const tokenIsPubliclyMintable = true;

async function deployERC721 (deployer, {ERC20Address}) {
  const ERC721Fields = [
    ERC721,
    ERC721TokenContractName,
    ERC721TokenContractSymbol,
    tokenBaseUri,
    ERC20Address,
    mintFee,
    treasurer,
    tokenIsSingleIssue,
    tokenIsPubliclyMintable,
  ]

  // Log fields.
  console.log('Attempting to deploy ERC721 contract...');

  // Deploy.
  await deployer.deploy(...ERC721Fields);
  let erc721 = await ERC721.deployed();

  // Log address.
  console.log("Deployed:" + erc721.address);

  return erc721;
}

module.exports = deployERC721;
