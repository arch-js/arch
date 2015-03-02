(function(){
  var react, path, dom, createComponent;
  react = require('react');
  path = require('path');
  dom = require('./dom');
  if (typeof window !== 'undefined') {
    global.React = react;
  }
  createComponent = function(spec){
    return dom(react.createClass(spec));
  };
  module.exports = {
    application: require('./application'),
    routes: require('./routes'),
    cursor: require('./cursor'),
    dom: dom,
    pureRenderMixin: require('./mixins/pure-render'),
    createComponent: createComponent
  };
}).call(this);
