(function(){
  var Immutable, ref$, map, take, reverse, each, join, split, isType, empty, objToPairs, first, arrayCursor, objectCursor, notifyChanges, performUpdate, Cursor, makeCursor;
  Immutable = require('immutable');
  ref$ = require('prelude-ls'), map = ref$.map, take = ref$.take, reverse = ref$.reverse, each = ref$.each, join = ref$.join, split = ref$.split, isType = ref$.isType, empty = ref$.empty, objToPairs = ref$.objToPairs, first = ref$.first;
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
    ref$ = Cursor.prototype, array.get = ref$.get, array.deref = ref$.deref, array.raw = ref$.raw, array.update = ref$.update, array.onChange = ref$.onChange, array.eq = ref$.eq;
    return array;
  };
  objectCursor = function(root, data, path){
    return new Cursor(root, data, path);
  };
  notifyChanges = function(from, to){
    return each(function(arg$){
      var path, listeners, n;
      path = arg$[0], listeners = arg$[1];
      if (n = path === ""
        ? to._root
        : to.get(path)) {
        if (!n.eq(path === ""
          ? from._root
          : from._root.get(path))) {
          return each(function(it){
            return it(n);
          })(
          listeners);
        }
      }
    })(
    objToPairs(
    from._root._listeners));
  };
  performUpdate = function(cursor, update, notify){
    var oldVal, newVal, newRoot, node;
    notify == null && (notify = true);
    oldVal = cursor.raw();
    newVal = update(cursor.deref());
    if (isType('Array', newVal) || isType('Object', newVal)) {
      newVal = Immutable.fromJS(newVal);
    }
    if (oldVal === newVal || Immutable.is(oldVal, newVal)) {
      return cursor;
    }
    if (empty(cursor._path)) {
      newRoot = makeCursor(newVal);
      node = newRoot;
    } else {
      newRoot = makeCursor(cursor._root._data.setIn(cursor._path, newVal));
      node = newRoot.get(join('.', cursor._path));
    }
    if (notify) {
      notifyChanges(cursor, newRoot);
      newRoot._listeners = cursor._root._listeners;
    }
    newRoot._updates = cursor._root._updates;
    return node;
  };
  Cursor = function(root, data, path){
    this._path = path;
    this._root = root || this;
    this._data = data ? Immutable.fromJS(data) : null;
    this._listeners = {};
    this._updates = [];
    return this;
  };
  Cursor.prototype.get = function(path){
    var val;
    path = this._path.concat(split('.', path));
    val = this._root._data.getIn(path);
    if (!val) {
      return null;
    }
    if (val instanceof Immutable.List) {
      return arrayCursor(this._root, null, val.size, path);
    } else {
      return objectCursor(this._root, null, path);
    }
  };
  Cursor.prototype.deref = function(){
    var data;
    data = this.raw();
    if (data && data.toJS) {
      return data.toJS();
    } else {
      return data;
    }
  };
  Cursor.prototype.raw = function(){
    return this._root._data.getIn(this._path);
  };
  Cursor.prototype.update = function(updater){
    var updates, cur;
    updates = this._root._updates;
    updates.push(updater);
    if (!(updates.length < 2)) {
      return;
    }
    cur = this;
    while (!empty(updates)) {
      cur = performUpdate(cur, first(updates));
      updates.shift();
    }
    return cur;
  };
  Cursor.prototype.transform = function(condition, updater){
    var x;
    x = this;
    while (!condition(x)) {
      x = performUpdate(x, updater, false);
    }
    return this.update(function(){
      return x.deref();
    });
  };
  Cursor.prototype.onChange = function(cbk){
    var key, ref$;
    key = join('.', this._path);
    (ref$ = this._root._listeners)[key] || (ref$[key] = []);
    return this._root._listeners[key].push(cbk);
  };
  Cursor.prototype.eq = function(cur){
    return deepEq$(this.raw(), cur.raw(), '===');
  };
  module.exports = makeCursor = function(data){
    if (isType('Array', data)) {
      return arrayCursor(null, data, data.length, []);
    } else {
      return objectCursor(null, data, []);
    }
  };
  function deepEq$(x, y, type){
    var toString = {}.toString, hasOwnProperty = {}.hasOwnProperty,
        has = function (obj, key) { return hasOwnProperty.call(obj, key); };
    var first = true;
    return eq(x, y, []);
    function eq(a, b, stack) {
      var className, length, size, result, alength, blength, r, key, ref, sizeB;
      if (a == null || b == null) { return a === b; }
      if (a.__placeholder__ || b.__placeholder__) { return true; }
      if (a === b) { return a !== 0 || 1 / a == 1 / b; }
      className = toString.call(a);
      if (toString.call(b) != className) { return false; }
      switch (className) {
        case '[object String]': return a == String(b);
        case '[object Number]':
          return a != +a ? b != +b : (a == 0 ? 1 / a == 1 / b : a == +b);
        case '[object Date]':
        case '[object Boolean]':
          return +a == +b;
        case '[object RegExp]':
          return a.source == b.source &&
                 a.global == b.global &&
                 a.multiline == b.multiline &&
                 a.ignoreCase == b.ignoreCase;
      }
      if (typeof a != 'object' || typeof b != 'object') { return false; }
      length = stack.length;
      while (length--) { if (stack[length] == a) { return true; } }
      stack.push(a);
      size = 0;
      result = true;
      if (className == '[object Array]') {
        alength = a.length;
        blength = b.length;
        if (first) {
          switch (type) {
          case '===': result = alength === blength; break;
          case '<==': result = alength <= blength; break;
          case '<<=': result = alength < blength; break;
          }
          size = alength;
          first = false;
        } else {
          result = alength === blength;
          size = alength;
        }
        if (result) {
          while (size--) {
            if (!(result = size in a == size in b && eq(a[size], b[size], stack))){ break; }
          }
        }
      } else {
        if ('constructor' in a != 'constructor' in b || a.constructor != b.constructor) {
          return false;
        }
        for (key in a) {
          if (has(a, key)) {
            size++;
            if (!(result = has(b, key) && eq(a[key], b[key], stack))) { break; }
          }
        }
        if (result) {
          sizeB = 0;
          for (key in b) {
            if (has(b, key)) { ++sizeB; }
          }
          if (first) {
            if (type === '<<=') {
              result = size < sizeB;
            } else if (type === '<==') {
              result = size <= sizeB
            } else {
              result = size === sizeB;
            }
          } else {
            first = false;
            result = size === sizeB;
          }
        }
      }
      stack.pop();
      return result;
    }
  }
}).call(this);
