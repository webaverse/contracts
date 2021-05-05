function cancelEntry(deposits, withdraws, currentLocation, nextLocation, currentAddress, transactionHash) {
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
    currentLocation = nextLocation;
    currentAddress = withdraw.returnValues.from;
    transactionHash = withdraw.transactionHash;

    return [
      deposits,
      withdraws,
      currentLocation,
      currentAddress,
      transactionHash,
    ];
  } else if (deposits.length > 0) {
    currentLocation += '-stuck';
    transactionHash = deposits[0].transactionHash;
    return [
      deposits,
      withdraws,
      currentLocation,
      currentAddress,
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
  currentAddress,
) {
  let currentLocation = 'mainnetsidechain';
  let transactionHash = '';

  // swap transfers
  {
    let changed = true;
    while (changed) {
      changed = false;

      // sidechain -> mainnet
      {
        const result = cancelEntry(sidechainDepositedEntries, mainnetWithdrewEntries, currentLocation, 'mainnet', currentAddress, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          sidechainDepositedEntries = result[0];
          mainnetWithdrewEntries = result[1];
          currentLocation = result[2];
          currentAddress = result[3];
          // transactionHash = result[4];
          changed = true;

          const result2 = cancelEntry(mainnetDepositedEntries, sidechainWithdrewEntries, currentLocation, 'mainnetsidechain', currentAddress, transactionHash);
          if (result2 && !/stuck/.test(result2[2])) {
            mainnetDepositedEntries = result2[0];
            sidechainWithdrewEntries = result2[1];
            currentLocation = result2[2];
            currentAddress = result2[3];
            // transactionHash = result2[4];
            changed = true;
          }
        }
      }

      // sidechain -> polygon
      {
        const result = cancelEntry(sidechainDepositedEntries, polygonWithdrewEntries, currentLocation, 'polygon', currentAddress, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          sidechainDepositedEntries = result[0];
          polygonWithdrewEntries = result[1];
          currentLocation = result[2];
          currentAddress = result[3];
          // transactionHash = result[4];
          changed = true;

          const result2 = cancelEntry(polygonDepositedEntries, sidechainWithdrewEntries, currentLocation, 'mainnetsidechain', currentAddress, transactionHash);
          if (result2 && !/stuck/.test(result2[2])) {
            polygonDepositedEntries = result2[0];
            sidechainWithdrewEntries = result2[1];
            currentLocation = result2[2];
            currentAddress = result2[3];
            // transactionHash = result2[4];
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
        const result = cancelEntry(sidechainDepositedEntries, sidechainWithdrewEntries, currentLocation, 'mainnetsidechain', currentAddress, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          sidechainDepositedEntries = result[0];
          sidechainWithdrewEntries = result[1];
          // currentLocation = result[2];
          // currentAddress = result[3];
          // transactionHash = result[4];
          changed = true;
        }
      }
      // mainnet -> mainnet
      {
        const result = cancelEntry(mainnetDepositedEntries, mainnetWithdrewEntries, currentLocation, 'mainnet', currentAddress, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          mainnetDepositedEntries = result[0];
          mainnetWithdrewEntries = result[1];
          // currentLocation = result[2];
          // currentAddress = result[3];
          // transactionHash = result[4];
          changed = true;
        }
      }
      // polygon -> polygon
      {
        const result = cancelEntry(polygonDepositedEntries, polygonWithdrewEntries, currentLocation, 'polygon', currentAddress, transactionHash);
        if (result && !/stuck/.test(result[2])) {
          polygonDepositedEntries = result[0];
          polygonWithdrewEntries = result[1];
          // currentLocation = result[2];
          // currentAddress = result[3];
          // transactionHash = result[4];
          changed = true;
        }
      }
    }
  }
  const danglingDepositedEntries = mainnetDepositedEntries
    .concat(sidechainDepositedEntries)
    .concat(polygonDepositedEntries);
  if (danglingDepositedEntries.length > 0) {
    currentLocation += '-stuck';
    transactionHash = danglingDepositedEntries[0].transactionHash;
    // console.log('got dangler 1', danglingDepositedEntries, transactionHash);
  } else {
    // console.log('got dangler 2', danglingDepositedEntries);
  }

  return [
    mainnetDepositedEntries,
    mainnetWithdrewEntries,
    sidechainDepositedEntries,
    sidechainWithdrewEntries,
    polygonDepositedEntries,
    polygonWithdrewEntries,
    currentLocation,
    currentAddress,
    transactionHash,
  ];
};
