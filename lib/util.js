
function timeout(ms, result = true) {
  return new Promise(resolve => setTimeout(resolve.bind(null, result), ms));
}

function makePromise() {
  let reject, resolve;

  const promise = new Promise((res, rej) => {
    reject = rej;
    resolve = res;
  })

  promise.reject = reject
  promise.resolve = resolve

  return promise;
}

function equalsAll(...args) { return args.every(y => args[0] === y)}


module.exports = {
  equalsAll,
  makePromise,
  timeout,
}
