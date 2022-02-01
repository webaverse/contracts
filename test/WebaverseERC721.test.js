const { expect, use } = require("chai");
// const { deployContract, MockProvider, solidity } = require("ethereum-waffle");
const { deployContract } = require("ethereum-waffle");
const { zeroAddress } = require("ethereumjs-util");
const WebaverseERC20Contract = require("../build/WebaverseERC20.json");
const WebaverseERC721Contract = require("../build/WebaverseERC721.json");

const { waffle } = require("hardhat");
const { solidity } = waffle;
const provider = waffle.provider;

use(solidity);

describe("WebaverseERC721", () => {
  const [wallet, walletTo] = provider.getWallets();
  let erc20Contract, token;

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

    token = await deployContract(wallet, WebaverseERC721Contract, [
      ERC721TokenContractName,
      ERC721TokenContractSymbol,
      tokenBaseUri,
      erc20Contract.address,
      mintFee,
      wallet.address,
      tokenIsPublicallyMintable,
    ]);
  });

  it("Contractor Initialization Test", async () => {
    await token.name();
    expect(await token.name()).to.equal(ERC721TokenContractName);
    expect(await token.symbol()).to.equal(ERC721TokenContractSymbol);
  });

  it("Mint Token", async () => {
    const tokenId = 1;
    await token.mintTokenId(wallet.address, tokenId);
    expect(await token.balanceOf(wallet.address)).to.equal(1);
    expect(await token.ownerOf(tokenId)).to.equal(wallet.address);
    expect(await token.totalSupply()).to.equal(1);
  });

  it("Mint emits events", async () => {
    const tokenId = 1;
    const mintAddress = zeroAddress;
    await expect(token.mintTokenId(wallet.address, tokenId))
      .to.emit(token, "Transfer")
      .withArgs(mintAddress, wallet.address, tokenId);
  });

  it("Transfer", async () => {
    const tokenId = 1;
    await token.mintTokenId(wallet.address, tokenId);
    // await token.transferFrom(wallet.address, walletTo.address, tokenId);
  });

  it("Transfer emits event", async () => {
    const tokenId = 1;
    await token.mintTokenId(wallet.address, tokenId);
    // await expect(token.transferFrom(wallet.address, walletTo.address, tokenId))
    //   .to.emit(token, "Transfer")
    //   .withArgs(wallet.address, walletTo.address, tokenId);
  });
});
