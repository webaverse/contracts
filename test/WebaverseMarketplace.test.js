const { expect, use } = require("chai");
const { deployContract, MockProvider, solidity } = require("ethereum-waffle");
const { Contract } = require("ethers");
const WebaverseERC20Contract = require("../build/WebaverseERC20.json");
const WebaverseERC721Contract = require("../build/WebaverseERC721.json");
const WebaverseMarketplace = require("../build/WebaverseMarketplace.json");

use(solidity);

describe("WebaverseMarketplace", () => {
  const [wallet, walletTo] = new MockProvider().getWallets();
  let erc20Contract, erc721Contract, marketplaceContract;

  const tokenName = "SILK";
  const tokenSymbol = "SILK";
  const tokenCap = "2147483648000000000000000000";

  const ERC721TokenContractName = "ASSET";
  const ERC721TokenContractSymbol = "ASSET";
  const tokenBaseUri = "https://tokens.webaverse.com/";
  const mintFee = 10;
  const tokenIsPublicallyMintable = true;

  beforeEach(async () => {
    erc20Contract = await deployContract(wallet, WebaverseERC20Contract, [
      tokenName,
      tokenSymbol,
      tokenCap,
    ]);

    await erc20Contract.mint(wallet.address, 1000);

    erc721Contract = await deployContract(wallet, WebaverseERC721Contract, [
      ERC721TokenContractName,
      ERC721TokenContractSymbol,
      tokenBaseUri,
      erc20Contract.address,
      mintFee,
      wallet.address,
      tokenIsPublicallyMintable,
    ]);


    marke = await deployContract(wallet, WebaverseMarketplace, [
      erc20Contract.address,
      erc721Contract.address,
    ]);

    erc721Contract.setMarketplaceAddress(marketplaceContract.address);
  });

  it("Assigns initial balance", async () => {
    expect(await erc20Contract.balanceOf(wallet.address)).to.equal(1000);
  });

  it("Transfer adds amount to destination account", async () => {
    await erc20Contract.transfer(walletTo.address, 7);
    expect(await erc20Contract.balanceOf(walletTo.address)).to.equal(7);
  });

  it("Transfer emits event", async () => {
    await expect(erc20Contract.transfer(walletTo.address, 7))
      .to.emit(erc20Contract, "Transfer")
      .withArgs(wallet.address, walletTo.address, 7);
  });

  it("Can not transfer above the amount", async () => {
    await expect(erc20Contract.transfer(walletTo.address, 1007)).to.be.reverted;
  });

  it("Can not transfer from empty account", async () => {
    const tokenFromOtherWallet = erc20Contract.connect(walletTo);
    await expect(tokenFromOtherWallet.transfer(wallet.address, 1)).to.be
      .reverted;
  });

  it("Calls totalSupply on ERC20 contract", async () => {
    await erc20Contract.totalSupply();
    expect("totalSupply").to.be.calledOnContract(erc20Contract);
  });

  it("Calls balanceOf with sender address on ERC20 contract", async () => {
    await erc20Contract.balanceOf(wallet.address);
    expect("balanceOf").to.be.calledOnContractWith(erc20Contract, [
      wallet.address,
    ]);
  });
});
