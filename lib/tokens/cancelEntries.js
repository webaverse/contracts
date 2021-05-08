function cancelEntry(deposits, withdraws, location, nextLocation, address, transactionHash) {
  let candidateWithdrawIndex = -1; let candidateDepositIndex = -1;
  withdraws.find((w, i) => {
    const candidateDeposit = deposits.find((d, i) => {
      if (d.returnValues.to === w.returnValues.from) {
        candidateDepositIndex = i;
        return true;
      } else {
        return false;
      }
    });

    if (candidateDeposit) {
      candidateWithdrawIndex = i;
      return true;
    } else {
      return false;
    }
  });

  if (candidateWithdrawIndex !== -1 && candidateDepositIndex !== -1) {
    deposits.splice(candidateDepositIndex, 1);
    const withdraw = withdraws.splice(candidateWithdrawIndex, 1)[0];
    location = nextLocation;
    address = withdraw.returnValues.from;
    transactionHash = withdraw.transactionHash;

    return [
      deposits,
      withdraws,
      location,
      address,
      transactionHash,
    ];
  } else if (deposits.length > 0) {
    location += '-stuck';
    transactionHash = deposits[0].transactionHash;
    return [
      deposits,
      withdraws,
      location,
      address,
      transactionHash,
    ];
  } else {
    return null;
  }
}

module.exports = function cancelEntries(
  mainnetDepositedEntries,
  mainnetWithdrewEntries,
  sidechainDepositedEntries,
  sidechainWithdrewEntries,
  polygonDepositedEntries,
  polygonWithdrewEntries,
  address,
) {
  let location = 'mainnetsidechain';
  let transactionHash = '';

  // swap transfers
  {
    let changed = true;
    while (changed) {
      changed = false;

      // sidechain -> mainnet
      {
        const result = cancelEntry(sidechainDepositedEntries, mainnetWithdrewEntries, location, 'mainnet', address, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          sidechainDepositedEntries = result[0];
          mainnetWithdrewEntries = result[1];
          location = result[2];
          address = result[3];
          changed = true;

          const result2 = cancelEntry(mainnetDepositedEntries, sidechainWithdrewEntries, location, 'mainnetsidechain', address, transactionHash);
          if (result2 && !/stuck/.test(result2[2])) {
            mainnetDepositedEntries = result2[0];
            sidechainWithdrewEntries = result2[1];
            location = result2[2];
            address = result2[3];
            changed = true;
          }
        }
      }

      // sidechain -> polygon
      {
        const result = cancelEntry(sidechainDepositedEntries, polygonWithdrewEntries, location, 'polygon', address, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          sidechainDepositedEntries = result[0];
          polygonWithdrewEntries = result[1];
          location = result[2];
          address = result[3];
          changed = true;

          const result2 = cancelEntry(polygonDepositedEntries, sidechainWithdrewEntries, location, 'mainnetsidechain', address, transactionHash);
          if (result2 && !/stuck/.test(result2[2])) {
            polygonDepositedEntries = result2[0];
            sidechainWithdrewEntries = result2[1];
            location = result2[2];
            address = result2[3];
            changed = true;
          }
        }
      }
    }
  }
  // self transfer
  {
    let changed = true;
    while (changed) {
      changed = false;

      // sidechain -> sidechain
      {
        const result = cancelEntry(sidechainDepositedEntries, sidechainWithdrewEntries, location, 'mainnetsidechain', address, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          sidechainDepositedEntries = result[0];
          sidechainWithdrewEntries = result[1];
          changed = true;
        }
      }

      // mainnet -> mainnet
      {
        const result = cancelEntry(mainnetDepositedEntries, mainnetWithdrewEntries, location, 'mainnet', address, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          mainnetDepositedEntries = result[0];
          mainnetWithdrewEntries = result[1];
          changed = true;
        }
      }

      // polygon -> polygon
      {
        const result = cancelEntry(polygonDepositedEntries, polygonWithdrewEntries, location, 'polygon', address, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          polygonDepositedEntries = result[0];
          polygonWithdrewEntries = result[1];
          changed = true;
        }
      }
    }
  }

  const danglingDepositedEntries = mainnetDepositedEntries
    .concat(sidechainDepositedEntries)
    .concat(polygonDepositedEntries);

  if (danglingDepositedEntries.length > 0) {
    location += '-stuck';
    transactionHash = danglingDepositedEntries[0].transactionHash;
  }

  return {
    entries: [
      mainnetDepositedEntries,
      mainnetWithdrewEntries,
      sidechainDepositedEntries,
      sidechainWithdrewEntries,
      polygonDepositedEntries,
      polygonWithdrewEntries,
    ],

    address,
    location,
    transactionHash,
  };
};
