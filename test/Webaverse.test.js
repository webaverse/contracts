const { expect } = require("chai");
const { ethers } = require("hardhat");

const { ClaimableVoucher } = require("../lib");

async function deploy() {
    const [signer, claimer, externalSigner, _] = await ethers.getSigners();

    let WebaverseFactory = await ethers.getContractFactory("Webaverse", signer);
    const Webaverse = await WebaverseFactory.deploy();
    await Webaverse.deployed();

    // the redeemerContract is an instance of the contract that's wired up to the redeemer's signing key
    const signerFactory = WebaverseFactory.connect(signer);
    const signerContract = signerFactory.attach(Webaverse.address);

    const claimerFactory = WebaverseFactory.connect(claimer);
    const claimerContract = claimerFactory.attach(Webaverse.address);

    const externalSignerFactory = WebaverseFactory.connect(externalSigner);
    const externalSignerContract = externalSignerFactory.attach(Webaverse.address);

    await signerContract.mint(signer.address, 1, "abcdef");
    await signerContract.mint(signer.address, 2, "xyzder");
    await signerContract.mint(signer.address, 3, "qwerty");

    let ERC721Factory = await ethers.getContractFactory("ERC721Mock");
    const ERC721 = await ERC721Factory.deploy("TEST", "test");
    await ERC721.deployed();

    const externalSignerFactoryERC721 = ERC721Factory.connect(externalSigner);
    const externalSignerERC721 = externalSignerFactoryERC721.attach(ERC721.address);

    await externalSignerERC721.mint(externalSigner.address, 1);
    await externalSignerERC721.mint(externalSigner.address, 2);
    await externalSignerERC721.mint(externalSigner.address, 3);

    const claimerFactoryERC721 = ERC721Factory.connect(claimer);
    const claimerERC721 = claimerFactoryERC721.attach(ERC721.address);

    return {
        signer,
        claimer,
        externalSigner,
        signerContract,
        claimerContract,
        externalSignerContract,
        externalSignerERC721,
        claimerERC721,
    };
}

describe("Claim", async function () {
    var validTokenIds = [1, 2, 3];
    var nonce = ethers.BigNumber.from(ethers.utils.randomBytes(4)).toNumber();
    var expiry = ethers.BigNumber.from(Math.round(+new Date() / 1000)).toNumber();
    context("With valid signature, valid nonce, valid expiry", async function () {
        it("Should redeem an NFT from a signed voucher", async function () {
            const {
                signer,
                claimer,
                externalSigner,
                signerContract,
                claimerContract,
                externalSignerContract,
            } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: signerContract,
                signer: signer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce,
                expiry + 100
            );

            //check if event transfer is emitted
            await expect(claimerContract.claim(claimer.address, voucher))
                .to.emit(claimerContract, "Transfer") // transfer from minter to redeemer
                .withArgs(signer.address, claimer.address, validTokenIds[0]);
        });
    });
    context("With invalid signature, invalid nonce, invalid expiry", async function () {
        it("Should fail to redeem an NFT with invalid signature", async function () {
            const { claimer, claimerContract } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce + 1,
                expiry + 100
            );
            await expect(claimerContract.claim(claimer.address, voucher)).to.be.revertedWith(
                "Authorization failed: Invalid signature"
            );
        });

        it("Should fail to redeem an NFT after the expiry has passed", async function () {
            const { signer, claimer, claimerContract } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: signer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce + 1,
                expiry - 100
            );
            await expect(claimerContract.claim(claimer.address, voucher)).to.be.revertedWith(
                "Voucher has already expired"
            );
        });

        it("Should fail to redeem an NFT with already used nonce", async function () {
            const { signer, claimer, signerContract, claimerContract } = await deploy();
            let claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: signer,
            });
            let voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce,
                expiry + 100
            );
            await claimerContract.claim(claimer.address, voucher);

            claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            voucher = await claimableVoucher.createVoucher(validTokenIds[0], nonce, expiry + 100);
            await expect(signerContract.claim(signer.address, voucher)).to.be.revertedWith(
                "Invalid nonce value"
            );
        });

        it("Should fail to redeem an NFT with modified voucher", async function () {
            const { claimer, claimerContract } = await deploy();
            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce + 1,
                expiry + 100
            );
            voucher.tokenId = validTokenIds[1];
            await expect(claimerContract.claim(claimer.address, voucher)).to.be.revertedWith(
                "Authorization failed: Invalid signature"
            );
        });
    });
});

describe("externalClaim", async function () {
    var validTokenIds = [1, 2, 3];
    var nonce = ethers.BigNumber.from(ethers.utils.randomBytes(4)).toNumber();
    var expiry = ethers.BigNumber.from(Math.round(+new Date() / 1000)).toNumber();
    context("With valid signature, valid nonce, valid expiry", async function () {
        it("Should redeem an NFT from a signed voucher", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC721,
            } = await deploy();

            await externalSignerERC721.approve(externalSignerContract.address, validTokenIds[0]);

            const claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce,
                expiry + 100
            );

            //check if event transfer is emitted
            const logs = await claimerContract.externalClaim(
                claimer.address,
                externalSignerERC721.address,
                voucher
            );
            const owner = await externalSignerERC721.ownerOf(validTokenIds[0]);
            await expect(owner == claimer.address);
        });
    });

    context("With invalid signature, invalid nonce, invalid expiry", async function () {
        it("Should fail to redeem an NFT with invalid signature", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC721,
            } = await deploy();

            await externalSignerERC721.approve(externalSignerContract.address, validTokenIds[0]);

            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce,
                expiry + 100
            );

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(
                    claimer.address,
                    externalSignerERC721.address,
                    voucher
                )
            ).to.be.revertedWith("Authorization failed: Invalid signature");
        });

        it("Should fail to redeem an NFT after the expiry has passed", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC721,
            } = await deploy();

            await externalSignerERC721.approve(externalSignerContract.address, validTokenIds[0]);

            const claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            const voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce,
                expiry - 50
            );

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(
                    claimer.address,
                    externalSignerERC721.address,
                    voucher
                )
            ).to.be.revertedWith("Voucher has already expired");
        });

        it("Should fail to redeem an NFT with already used nonce", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC721,
                claimerERC721,
            } = await deploy();

            await externalSignerERC721.approve(externalSignerContract.address, validTokenIds[0]);

            let claimableVoucher = new ClaimableVoucher({
                contract: externalSignerContract,
                signer: externalSigner,
            });
            let voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce,
                expiry + 100
            );
            await claimerContract.externalClaim(
                claimer.address,
                externalSignerERC721.address,
                voucher
            );

            await claimerERC721.approve(externalSignerContract.address, validTokenIds[0]);

            claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            voucher = await claimableVoucher.createVoucher(validTokenIds[0], nonce, expiry + 100);

            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(
                    claimer.address,
                    externalSignerERC721.address,
                    voucher
                )
            ).to.be.revertedWith("Invalid nonce value");
        });

        it("Should fail to redeem an NFT with modified voucher", async function () {
            const {
                claimer,
                externalSigner,
                claimerContract,
                externalSignerContract,
                externalSignerERC721,
            } = await deploy();

            await externalSignerERC721.approve(externalSignerContract.address, validTokenIds[0]);

            const claimableVoucher = new ClaimableVoucher({
                contract: claimerContract,
                signer: claimer,
            });
            let voucher = await claimableVoucher.createVoucher(
                validTokenIds[0],
                nonce,
                expiry + 100
            );
            voucher.tokenId = 1;
            //check if event transfer is emitted
            await expect(
                claimerContract.externalClaim(
                    claimer.address,
                    externalSignerERC721.address,
                    voucher
                )
            ).to.be.revertedWith("Authorization failed: Invalid signature");
        });
    });
});
