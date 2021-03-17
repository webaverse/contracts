# contracts

Webaverse contracts.

Audit: https://github.com/webaverse/audit

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

# OpenSea links

## mainnet
https://opensea.io/webaverse

## rinkeby
https://testnets.opensea.io/get-listed/step-two

# Addressess used

burn: 0x000000000000000000000000000000000000dEaD

mainnet signer: 0x6a93d2daf3b017c77d433628e690ddee0d561960

rinkeby signer: 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4

treasury: 0xd459de6c25f61ed5dcec66468dab39fc70c0ff68
