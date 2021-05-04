const ERC721 = artifacts.require('WebaverseERC721');
const {mintFee, tokenBaseUri, treasurer} = require('../const');

const ERC721TokenContractName = 'ASSET';
const ERC721TokenContractSymbol = 'ASSET';
const tokenIsSingleIssue = false;
const tokenIsPubliclyMintable = true;

module.exports.deployERC721 = async function(deployer, {erc20}) {
  const ERC721Fields = [
    ERC721,
    ERC721TokenContractName,
    ERC721TokenContractSymbol,
    tokenBaseUri,
    erc20.address,
    mintFee,
    treasurer,
    tokenIsSingleIssue,
    tokenIsPubliclyMintable,
  ];

  // Log fields.
  console.log(':: Deploying ERC721 contract.');

  // Deploy.
  await deployer.deploy(...ERC721Fields);
  const erc721 = await ERC721.deployed();

  // Log address.
  console.log('Deployed:' + erc721.address);

  return erc721;
};
