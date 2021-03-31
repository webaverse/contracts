# contracts

Webaverse contracts.

Audit: https://github.com/webaverse/audit

# Setup and Deployment

First, copy .env.default and rename it to .env, then configure it for the network you want to deploy to.

```
npm install
npm run deploy-<network> // i.e. npm run deploy-polygon
```
Consult package.json for more options

# mainnet

## Account
// nothing
## FT
SILK, SILK, 2147483648000000000000000000
## FTProxy
${FT}, 0x6a93d2daf3b017c77d433628e690ddee0d561960, 1
## NFT
ASSET, ASSET, "https://tokens.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, false, false
## NFTProxy
${NFT}, 0x6a93d2daf3b017c77d433628e690ddee0d561960, 2
## Trade
${FT}, ${NFT}, 0x6a93d2daf3b017c77d433628e690ddee0d561960
## LAND
LAND, LAND, "https://land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0x6a93d2daf3b017c77d433628e690ddee0d561960, 3

# mainnetsidechain

## Account
// nothing
## FT
SILK, SILK, 2147483648000000000000000000
## FTProxy
${FT}, 0x6a93d2daf3b017c77d433628e690ddee0d561960, 4
## NFT
ASSET, ASSET, "https://tokens.webaverse.com/", ${FT}, 10, 0xd459de6c25f61ed5dcec66468dab39fc70c0ff68, false, true
## NFTProxy
${NFT}, 0x6a93d2daf3b017c77d433628e690ddee0d561960, 5
## Trade
${FT}, ${NFT}, 0x6a93d2daf3b017c77d433628e690ddee0d561960
## LAND
LAND, LAND, "https://land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0x6a93d2daf3b017c77d433628e690ddee0d561960, 6

# testnet / rinkeby

## Account
// nothing
## FT
SILK, SILK, 2147483648000000000000000000
## FTProxy
${FT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 1
## NFT
ASSET, ASSET, "https://tokens.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, false, false
## NFTProxy
${NFT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 2
## Trade
${FT}, ${NFT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
## LAND
LAND, LAND, "https://land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 3

# testnetsidechain

## Account
// nothing
## FT
SILK, SILK, 2147483648000000000000000000
## FTProxy
${FT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 4
## NFT
ASSET, ASSET, "https://tokens.webaverse.com/", ${FT}, 10, 0xd459de6c25f61ed5dcec66468dab39fc70c0ff68, false, true
## NFTProxy
${NFT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 5
## Trade
${FT}, ${NFT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
## LAND
LAND, LAND, "https://land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 6

# polygon

## Account
// nothing
## FT
SILK, SILK, 2147483648000000000000000000
## FTProxy
${FT}, 0x5d4e8c60b51a7e5941f10d67090026e1877d15d7, 1
## NFT
ASSET, ASSET, "https://tokens.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, false, false
## NFTProxy
${NFT}, 0x5d4e8c60b51a7e5941f10d67090026e1877d15d7, 2
## Trade
${FT}, ${NFT}, 0x5d4e8c60b51a7e5941f10d67090026e1877d15d7
## LAND
LAND, LAND, "https://land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0x5d4e8c60b51a7e5941f10d67090026e1877d15d7, 3

# testpolygon

## Account
// nothing
## FT
SILK, SILK, 2147483648000000000000000000
## FTProxy
${FT}, 0xD2e62C19d31A987870f1582163A99702E3628D5E, 4
## NFT
ASSET, ASSET, "https://tokens.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, false, false
## NFTProxy
${NFT}, 0xD2e62C19d31A987870f1582163A99702E3628D5E, 5
## Trade
${FT}, ${NFT}, 0xD2e62C19d31A987870f1582163A99702E3628D5E
## LAND
LAND, LAND, "https://land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0xD2e62C19d31A987870f1582163A99702E3628D5E, 6

# OpenSea links

## mainnet
https://opensea.io/webaverse

## testnet (rinkeby)
https://testnets.opensea.io/get-listed/step-two

# Addressess used

burn: 0x000000000000000000000000000000000000dEaD

mainnet signer: 0x6a93d2daf3b017c77d433628e690ddee0d561960

testnet signer: 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4

polygon signer: 0x5d4e8c60b51a7e5941f10d67090026e1877d15d7

testnetpolygon signer: 0xD2e62C19d31A987870f1582163A99702E3628D5E

treasury: 0xd459de6c25f61ed5dcec66468dab39fc70c0ff68
