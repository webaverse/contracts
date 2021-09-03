const { expect, use } = require("chai");
const { deployContract } = require("ethereum-waffle");
const { zeroAddress } = require("ethereumjs-util");
const { Contract } = require("ethers");
const WebaverseERC20Contract = require("../build/WebaverseERC20.json");
const WebaverseERC721Contract = require("../build/WebaverseERC721.json");
const WebaverseMarketplace = require("../build/WebaverseMarketplace.json");

const { waffle } = require("hardhat");
const { solidity } = waffle;
const provider = waffle.provider;

use(solidity);

describe("WebaverseMarketplace", () => {
  const [wallet, walletTo] = provider.getWallets();
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

    marketplaceContract = await deployContract(wallet, WebaverseMarketplace, [
      erc20Contract.address,
      erc721Contract.address,
    ]);

    await erc721Contract.setMarketplaceAddress(marketplaceContract.address);
  });

  it("Mint Token", async () => {
    const tokenId = 1;
    await erc721Contract.mintTokenId(wallet.address, tokenId);
    expect(await erc721Contract.balanceOf(wallet.address)).to.equal(1);
    expect(await erc721Contract.ownerOf(tokenId)).to.equal(wallet.address);
    expect(await erc721Contract.totalSupply()).to.equal(1);
  });

  it("Mint Token and create market item", async () => {
    const tokenId = 1;
    await erc721Contract.mintTokenId(wallet.address, tokenId);
    expect(await erc721Contract.balanceOf(wallet.address)).to.equal(1);
    expect(await erc721Contract.ownerOf(tokenId)).to.equal(wallet.address);
    expect(await erc721Contract.totalSupply()).to.equal(1);

    await marketplaceContract.createMarketItem(erc721Contract.address, 1, 100, {
      from: wallet.address,
      gasLimit: 300000000,
      value: 100,
    });

    // const item = await marketplaceContract.getMarketItem(1);
    // console.log(item);
  });
});
