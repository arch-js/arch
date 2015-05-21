(function(){
  var path, dom, serverRendering, createComponent, redirect;
  global.React = require('react/addons');
  path = require('path');
  dom = require('./dom');
  serverRendering = require('./server-rendering');
  createComponent = function(spec){
    return dom(React.createClass(spec));
  };
  redirect = function(path){
    if (this.routes.running) {
      return this.routes.navigate(path);
    } else {
      return serverRendering.redirect(path);
    }
  };
  module.exports = {
    application: require('./application'),
    CLIENT: process.env.ARCH_ENV === 'browser',
    routes: require('./routes'),
    cursor: require('./cursor'),
    dom: dom,
    DOM: dom,
    redirect: redirect,
    createComponent: createComponent
  };
}).call(this);
