(function(){
  var path;
  path = require('path');
  module.exports = {
    environment: process.env.NODE_ENV || 'development',
    port: 3000,
    'public': 'dist'
  };
}).call(this);
