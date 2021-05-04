
module.exports.getChainNames = chainName => {
  const mainnetChainName =
    chainName
      .replace(/polygon/, 'mainnet')
      .replace(/sidechain/, '')
    || 'mainnet';

  const sidechainChainName = mainnetChainName + 'sidechain';
  const polygonChainName = mainnetChainName.replace(/mainnet/, '') + 'polygon';

  return {
    mainnetChainName,
    sidechainChainName,
    polygonChainName,
  };
};
