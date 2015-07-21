(function(){
  var path, rc;
  path = require('path');
  rc = require('rc');
  module.exports = rc('arch', {
    appPath: path.resolve('.'),
    archPath: path.dirname(require.resolve('../package.json')),
    bundle: true,
    debug: false,
    environment: process.env.NODE_ENV || 'development',
    minify: process.env.NODE_ENV === 'production',
    'public': 'dist',
    port: 3000,
    watch: process.env.NODE_ENV !== 'production'
  });
}).call(this);
