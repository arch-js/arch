(function(){
  var react, path, factorify, factorifyAll, createComponent;
  react = require('react');
  path = require('path');
  factorify = function(klass){
    return react.createFactory(klass);
  };
  factorifyAll = function(obj){
    return Obj.map(function(it){
      return factorify(it);
    })(
    obj);
  };
  createComponent = function(spec){
    return react.createFactory(react.createClass(spec));
  };
  module.exports = {
    application: require('./application'),
    routes: require('./routes'),
    cursor: require('./cursor'),
    createComponent: createComponent,
    factorify: factorify,
    factorifyAll: factorifyAll
  };
}).call(this);
