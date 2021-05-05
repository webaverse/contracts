
function timeout(ms, result = true) {
  return new Promise(resolve => setTimeout(resolve.bind(null, result), ms));
}

function makePromise() {
  let reject, resolve;

  const promise = new Promise((res, rej) => {
    reject = rej;
    resolve = res;
  });

  promise.reject = reject;
  promise.resolve = resolve;

  return promise;
}

function filterUnique(v, i, a) { return a.indexOf(v) === i; }

function equalsAll(...args) { return args.every(x => x === args[0]); }

function pull(array, item) {
  return pullFromIndex(array, array.indexOf(item));
}

function pullFromIndex(array, index = 0) {
  return [...array.slice(0, index), ...array.slice(index + 1)];
}

module.exports = {
  equalsAll,
  filterUnique,
  makePromise,
  pull,
  pullFromIndex,
  timeout,
};
