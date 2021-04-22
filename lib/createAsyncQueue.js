const {makePromise} = require('./util');


module.exports.createAsyncQueue = () => ({
  _locked: false,
  _queue: [],

  _add(f) {
    const promise = makePromise();
    this._queue.push(async () => promise.resolve(await this._exec(f)));
    return promise;
  },

  async _exec(f) {
    this._lock();
    const result = await f();
    this._unlock();
    return result;
  },

  _lock() {
    this._locked = true
  },

  _next() {
    if (this._queue.length > 0) {
      this._queue.shift()();
    }
  },

  _unlock() {
    this._locked = false;
    this._next();
  },

  async run(f) {
    return this._locked
      ? this._add(f)
      : this._exec(f);
  }
})
