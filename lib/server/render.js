(function(){
  var xssFilters, jade, path, prelude, map, __template, escapeFilter;
  xssFilters = require('xss-filters');
  jade = require('jade');
  path = require('path');
  prelude = require('prelude-ls');
  map = prelude.Obj.map;
  __template = jade.compileFile(path.join(__dirname, 'index.jade'));
  exports.escapeState = function(it){
    return xssFilters.inHTMLData(it);
  };
  escapeFilter = function(k, v){
    if (deepEq$(typeof v, 'string', '===')) {
      return exports.escapeState(v);
    } else {
      return v;
    }
  };
  exports.stringifyState = function(it){
    return JSON.stringify(it, escapeFilter);
  };
  exports.renderBody = function(meta, body, appState, options){
    var stringifyState, bundlePath, archBody, layout, title;
    stringifyState = exports.stringifyState;
    bundlePath = options.environment === 'development'
      ? "http://localhost:3001/app.js"
      : "/" + options['public'] + "/app.js";
    archBody = __template({
      'public': options['public'],
      bundle: bundlePath,
      body: body,
      state: stringifyState(appState)
    });
    layout = meta.layout, title = meta.title;
    return layout({
      body: archBody,
      title: title
    });
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
