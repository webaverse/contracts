const {runTransaction} = require('./runTransaction');


module.exports.replayEvents = async function(
  events,
  contractName,
  method,
  fields
) {
  for (const event of events) {
    const args = fields.map( f => event.returnValues[f]);

    await runTransaction(
      contractName,
      method,
      ...args,
    );
  }
}
