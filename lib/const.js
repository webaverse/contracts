const networkTypes = {
  "mainnet": "mainnet",
  "mainnetsidechain": "mainnetsidechain",
  "polygon": "polygon",
  "testnet": "testnet",
  "testnetsidechain": "testnetsidechain",
  "testnetpolygon": "testnetpolygon",
  "development": "development"
}

const signers = {
  "mainnet": process.env.mainnetSignerAddress,
  "mainnetsidechain": process.env.mainnetsidechainSignerAddress,
  "polygon": process.env.polygonSignerAddress,
  "testnet": process.env.testnetSignerAddress,
  "testnetsidechain": process.env.testnetsidechainSignerAddress,
  "testnetpolygon": process.env.testnetpolygonSignerAddress
}

const treasurers = {
  "mainnet": process.env.mainnetTreasuryAddress,
  "mainnetsidechain": process.env.mainnetsidechainTreasuryAddress,
  "polygon": process.env.polygonTreasuryAddress,
  "testnet": process.env.testnetTreasuryAddress,
  "testnetsidechain": process.env.testnetsidechainTreasuryAddress,
  "testnetpolygon": process.env.testnetpolygonTreasuryAddress
}

const network = networkTypes[ process.argv[4]];
const signer = signers[network];
const treasurer = treasurers[network];

const storageHost = 'https://ipfs.exokit.org';
const tokenBaseUri = "https://tokens.webaverse.com/";

const mintFee = 10;

const accountKeys = [
  'name',
  'avatarId',
  'avatarName',
  'avatarExt',
  'avatarPreview',
  'loadout',
  'homeSpaceId',
  'homeSpaceName',
  'homeSpaceExt',
  'homeSpacePreview',
  'ftu',
  // 'mainnetAddress',
  'addressProofs',
];


module.exports = {
  network,
  signer,
  treasurer,
  storageHost,
  tokenBaseUri,
  mintFee,
  accountKeys,
};
