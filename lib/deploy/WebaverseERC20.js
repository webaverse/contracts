const ERC20 = artifacts.require('WebaverseERC20');

const ERC20ContractName = 'SILK';
const ERC20Symbol = 'SILK';

module.exports.deployERC20 = async function(deployer) {
  // Log fields.
  console.log(':: Deploying ERC20 contract.');

  // Deploy
  await deployer.deploy(ERC20, ERC20ContractName, ERC20Symbol, 10);
  const erc20 = await ERC20.deployed();

  // Log address.
  console.log('Deployed:' + erc20.address);

  return erc20;
};
