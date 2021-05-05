
module.exports.assert = assertion => {
  if (assertion[0]) console.log(assertion[1]);
  else throw new Error(String(assertion[2]));
};
