const { ClaimableVoucher } = require('../lib')
import { ethers } from "ethers";
import ABI from '../build/contracts/Webaverse.json';

window.onload = async () => {
    await window.ethereum.enable();
    const contractAddress = "0x6B2b44aE5cb9F23dFF68C998eC12d56b6B35DAe8";
    const provider = new ethers.providers.Web3Provider((window as any).ethereum)
    const signer = provider.getSigner()
    let contract = new ethers.Contract(contractAddress, ABI.abi, signer);
    let voucher: any;

    async function claim(tokenId: number, voucher: any) {
        if (voucher.tokenId === tokenId) {
            try {
                await contract.claim(await signer.getAddress(), voucher);

                contract.on("Transfer", (from, to, tokenId) => {
                    console.log("From : ", from, "To :", to, "Token ID :", tokenId.toNumber());
                    (<HTMLInputElement>document.getElementById("claimText")).innerHTML = "Claimed !";
                });
            } catch (err) {
                console.log(err.error.message);
                (<HTMLInputElement>document.getElementById("claimText")).innerHTML = "Error !";
            }
        }
    }


    async function createVocuher(tokenId: number) {
        const claimableVoucher = new ClaimableVoucher({ contractAddress: contractAddress, signer: signer })

        let timestamp = Math.round(new Date().getTime() / 1000) + 1000;
        let nonce = await contract.nonces(await signer.getAddress());

        try {
            voucher = await claimableVoucher.createVoucher(tokenId, nonce, timestamp);
            (<HTMLInputElement>document.getElementById("createText")).innerHTML = "Created !";
        } catch (err) {
            (<HTMLInputElement>document.getElementById("createText")).innerHTML = "Error !";
        }

        console.log(voucher)
    }

    document.getElementById("createBtn")?.addEventListener("click", (e) => {
        e.preventDefault()
        let tokenId = (<HTMLInputElement>document.getElementById("transferID")).value;
        createVocuher(parseInt(tokenId));
    })

    document.getElementById("claimBtn")?.addEventListener("click", (e) => {
        e.preventDefault()
        let tokenId = (<HTMLInputElement>document.getElementById("transferID")).value;
        claim(parseInt(tokenId), voucher);
    })
}
