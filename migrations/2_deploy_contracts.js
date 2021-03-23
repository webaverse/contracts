const Account = artifacts.require("WebaverseAccount");
const ERC20 = artifacts.require("WebaverseERC20");
const ERC20Proxy = artifacts.require("WebaverseERC20Proxy");
const ERC721 = artifacts.require("WebaverseERC721");
const ERC721Proxy = artifacts.require("WebaverseERC721Proxy");
const Trade = artifacts.require("WebaverseTrade");

module.exports = function(deployer) {
  deployer.deploy(Account);
  /** Constructor is empty. */

  /**
  name, symbol, cap
  FT, SILK, 2147483648000000000000000000
   */
  deployer.deploy(ERC20);

  /**
  parentAddress, signerAddress, _chainId
  ???, ???, ???
  */
  deployer.deploy(ERC20Proxy);

  /**
  name, symbol, baseUri, _erc20Contract, _mintFee, _treasuryAddress, _isSingleIssue, _isPublicallyMintable
  ???, ???, ???, ???, ???, ???, ???, ???
  */
  deployer.deploy(ERC721);

  /** parentAddress, signerAddress, _chainId
   * ???, ???, ???
  */
  deployer.deploy(ERC721Proxy);

    /** parentERC20Address, parentERC721Address, signerAddress
     * ???, ???, ???
    */

  deployer.deploy(Trade);
};
