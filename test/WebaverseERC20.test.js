import { expect, use } from "chai";
import { Contract } from "ethers";
import { deployContract, MockProvider, solidity } from "ethereum-waffle";
import WebaverseERC20Contract from "../build/WebaverseERC20.json";

use(solidity);

describe("WebaverseERC20Contract", () => {
  const [wallet, walletTo] = new MockProvider().getWallets();
  let erc20Contract, erc721Contract, marketplaceContract;

  beforeEach(async () => {
    erc20Contract = await deployContract(wallet, WebaverseERC20Contract, [
      "silk",
      "silk",
      "2147483648000000000000000000",
    ]);
    await erc20Contract.mint(wallet.address, 1000);
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
