(function(){
  var react, cursor, ref$, first, tail, each, keys, _cursor, isCursor, objIsEl, isNode, component, dom, slice$ = [].slice;
  react = require('react');
  cursor = require('./cursor');
  ref$ = require('prelude-ls'), first = ref$.first, tail = ref$.tail, each = ref$.each, keys = ref$.keys;
  _cursor = cursor([]);
  isCursor = function(it){
    return difference(keys(
    it), keys(
    _cursor)).length === 0;
  };
  objIsEl = function(it){
    if (isType('Array', it)) {
      return true;
    }
    return react.isValidElement(it);
  };
  isNode = function(it){
    switch (typeof it) {
    case 'number':
      return true;
    case 'string':
      return true;
    case 'boolean':
      return !it;
    case 'object':
      return objIsEl(it);
    default:
      return false;
    }
  };
  component = function(el, args){
    var props, children;
    props = first(args) || {};
    children = tail(args);
    if (isNode(props)) {
      children = args;
      props = {};
    }
    props.children = children;
    return react.createElement(el, props);
  };
  dom = function(el){
    return function(){
      var args;
      args = slice$.call(arguments);
      return component(el, args);
    };
  };
  each(function(it){
    return dom[it] = dom(it);
  })(
  keys(
  react.DOM));
  module.exports = dom;
}).call(this);
