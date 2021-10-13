require("dotenv").config({ path: "./.env" });

module.exports = {
    testnet: {
        mnemonic: process.env.TEST_SECRET,
        priv_key: process.env.TEST_PRIV_KEY,
        signer_key: process.env.SIGNER_PRIVATE_KEY,
        claimer_key: process.env.CLAIMER_PRIVATE_KEY,
        external_signer_key: process.env.EXTERNAL_SIGNER_PRIVATE_KEY,
        infura_key: process.env.INFURA_KEY,
    },
    mainnet: {},
};
