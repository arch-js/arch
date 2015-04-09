(function(){
  var Immutable, bluebird, ref$, map, take, reverse, each, join, split, isType, empty, UpdateTransaction, isPromise, arrayCursor, objectCursor, notifyListeners, flushUpdates, performUpdate, Cursor, toString$ = {}.toString;
  Immutable = require('immutable');
  bluebird = require('bluebird');
  ref$ = require('prelude-ls'), map = ref$.map, take = ref$.take, reverse = ref$.reverse, each = ref$.each, join = ref$.join, split = ref$.split, isType = ref$.isType, empty = ref$.empty;
  UpdateTransaction = function(){
    this.promises = [];
  };
  isPromise = function(it){
    return it && it.then && toString$.call(it.then).slice(8, -1) === 'Function';
  };
  arrayCursor = function(root, data, len, path){
    var array, ref$;
    array = map(function(it){
      return new Cursor(root, null, path.concat([it]));
    })(
    (function(){
      var i$, to$, results$ = [];
      for (i$ = 0, to$ = len; i$ < to$; ++i$) {
        results$.push(i$);
      }
      return results$;
    }()));
    array._path = path;
    array._root = root || this;
    array._data = data ? Immutable.fromJS(data) : null;
    array._listeners = {};
    array._transactions = [];
    array._updates = [];
    ref$ = Cursor.prototype, array.get = ref$.get, array.deref = ref$.deref, array.raw = ref$.raw, array.update = ref$.update, array._swap = ref$._swap, array.onChange = ref$.onChange;
    return array;
  };
  objectCursor = function(root, data, path){
    return new Cursor(root, data, path);
  };
  notifyListeners = function(listeners, transactions, path, newData){
    var paths;
    paths = each(function(path){
      var key;
      key = join('.')(
      path);
      if (!isType('Array', listeners[key])) {
        return;
      }
      return each(function(it){
        var payload, maybePromise;
        payload = newData.getIn(path);
        if (payload.toJS) {
          payload = payload.toJS();
        }
        maybePromise = it(payload);
        if (isPromise(maybePromise)) {
          return each(function(it){
            return it.promises.push(maybePromise);
          })(
          transactions);
        }
      })(
      listeners[key]);
    })(
    reverse(
    map(function(it){
      return take(it)(
      path);
    })(
    (function(){
      var i$, to$, results$ = [];
      for (i$ = 0, to$ = path.length; i$ <= to$; ++i$) {
        results$.push(i$);
      }
      return results$;
    }()))));
  };
  flushUpdates = function(updates){
    var ref$, cursor, update, results$ = [];
    while (updates.length > 0) {
      ref$ = updates[0], cursor = ref$[0], update = ref$[1];
      performUpdate(cursor, update);
      results$.push(updates.shift());
    }
    return results$;
  };
  performUpdate = function(cursor, update){
    var oldVal, newVal, newData;
    oldVal = cursor.raw();
    newVal = update(cursor.deref());
    if (isType('Array', newVal) || isType('Object', newVal)) {
      newVal = Immutable.fromJS(newVal);
    }
    if (oldVal === newVal) {
      return;
    }
    if (Immutable.is(oldVal, newVal)) {
      return;
    }
    newData = empty(cursor._path)
      ? newVal
      : cursor._root._data.setIn(cursor._path, newVal);
    cursor._root._swap(newData);
    return notifyListeners(cursor._root._listeners, cursor._root._transactions, cursor._path, newData);
  };
  Cursor = function(root, data, path){
    this._path = path;
    this._root = root || this;
    this._data = data ? Immutable.fromJS(data) : null;
    this._listeners = {};
    this._transactions = [];
    this._updates = [];
    return this;
  };
  Cursor.prototype.get = function(path){
    var val;
    path = this._path.concat(split('.', path));
    val = this._root._data.getIn(path);
    if (val instanceof Immutable.List) {
      return arrayCursor(this._root, null, val.size, path);
    } else {
      return objectCursor(this._root, null, path);
    }
  };
  Cursor.prototype.deref = function(){
    var data;
    data = this.raw();
    if (typeof data === 'undefined') {
      return null;
    }
    if (data && data.toJS) {
      return data.toJS();
    } else {
      return data;
    }
  };
  Cursor.prototype.raw = function(){
    return this._root._data.getIn(this._path);
  };
  Cursor.prototype.update = function(cbk){
    var updates, ref$, cursor, update, results$ = [];
    updates = this._root._updates;
    updates.push([this, cbk]);
    if (!(updates.length < 2)) {
      return;
    }
    while (!empty(updates)) {
      ref$ = updates[0], cursor = ref$[0], update = ref$[1];
      performUpdate(cursor, update);
      results$.push(updates.shift());
    }
    return results$;
  };
  Cursor.prototype._swap = function(newData){
    if (this !== this._root) {
      throw "_swap can only be called on the root cursor";
    }
    return this._data = newData;
  };
  Cursor.prototype.onChange = function(cbk){
    var key, ref$;
    key = join('.', this._path);
    (ref$ = this._root._listeners)[key] || (ref$[key] = []);
    return this._root._listeners[key].push(cbk);
  };
  Cursor.prototype.startTransaction = function(){
    var t;
    t = new UpdateTransaction();
    this._root._transactions.push(t);
    return t;
  };
  Cursor.prototype.endTransaction = function(transaction){
    var i;
    i = this._root._transactions.indexOf(transaction);
    if (i < 0) {
      throw new Error("Transaction isn't running");
    }
    if (empty(transaction.promises)) {
      return bluebird.resolve();
    }
    return bluebird.all(transaction.promises);
  };
  module.exports = function(data){
    if (isType('Array', data)) {
      return arrayCursor(null, data, data.length, []);
    } else {
      return objectCursor(null, data, []);
    }
  };
}).call(this);
