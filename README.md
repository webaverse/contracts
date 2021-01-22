# contracts

Webaverse contracts.

Audit: https://github.com/webaverse/audit

# mainnet

## Account
// nothing
## FT
FLUX, FLUX, 2147483648000000000000000000
## FTProxy
${FT}, 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656, 1
## NFT
ASSET, ASSET, "https://tokens.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, false, false
## NFTProxy
${NFT}, 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656, 2
## Trade
${FT}, ${NFT}, 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656
## LAND
LAND, LAND, "https://land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656, 5

# mainnetsidechain

## Account
// nothing
## FT
FLUX, FLUX, 2147483648000000000000000000
## FTProxy
${FT}, 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656, 3
## NFT
ASSET, ASSET, "https://tokens.webaverse.com/", ${FT}, 10, 0x1c4a2cd3559816bdad90a7405690728f0a2ff37f, false, true
## NFTProxy
${NFT}, 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656, 4
## Trade
${FT}, ${NFT}, 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656
## LAND
LAND, LAND, "https://land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656, 6

# rinkeby

## Account
// nothing
## FT
FLUX, FLUX, 2147483648000000000000000000
## FTProxy
${FT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 1
## NFT
ASSET, ASSET, "https://rinkebysidechain-tokens.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, false, false
## NFTProxy
${NFT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 2
## Trade
${FT}, ${NFT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
## LAND
LAND, LAND, "https://rinkebysidechain-land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 5

# mainnetsidechain

## Account
// nothing
## FT
FLUX, FLUX, 2147483648000000000000000000
## FTProxy
${FT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 3
## NFT
ASSET, ASSET, "https://rinkebysidechain-tokens.webaverse.com", ${FT}, 10, 0x1c4a2cd3559816bdad90a7405690728f0a2ff37f, false, true
## NFTProxy
${NFT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 4
## Trade
${FT}, ${NFT}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
## LAND
LAND, LAND, "https://rinkebysidechain-land.webaverse.com/", ${FT}, 0, 0x000000000000000000000000000000000000dEaD, true, false
## LANDProxy
${LAND}, 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4, 6

# OpenSea links

## mainnet
https://opensea.io/webaverse

## rinkeby
https://testnets.opensea.io/get-listed/step-two

# Addressess used

burn: 0x000000000000000000000000000000000000dEaD
mainnet signer: 0xd7523103ba15c1dfcf0f5ea1c553bc18179ac656
rinkeby signer: 0xfa80e7480e9c42a9241e16d6c1e7518c1b1757e4
treasury: 0x1c4a2cd3559816bdad90a7405690728f0a2ff37f
