(function(){
  var react, path, dom, factorify, factorifyAll, createComponent;
  react = require('react');
  path = require('path');
  dom = require('./dom');
  factorify = function(klass){
    return dom(klass);
  };
  factorifyAll = function(obj){
    return Obj.map(function(it){
      return dom(it);
    })(
    obj);
  };
  createComponent = function(spec){
    return dom(react.createClass(spec));
  };
  module.exports = {
    application: require('./application'),
    routes: require('./routes'),
    cursor: require('./cursor'),
    dom: dom,
    createComponent: createComponent,
    factorify: factorify,
    factorifyAll: factorifyAll
  };
}).call(this);
