(function(){
  var rc, defaultConfig;
  rc = require('rc');
  defaultConfig = require('./default-config');
  module.exports = function(opts){
    opts == null && (opts = {});
    return rc('arch', import$(clone$(defaultConfig), opts));
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);
