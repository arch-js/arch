(function(){
  var path, rc, lson, conf;
  path = require('path');
  rc = require('rc');
  lson = require('lson');
  conf = {
    appPath: path.resolve('.'),
    archPath: path.dirname(require.resolve('../package.json')),
    bundle: true,
    debug: false,
    environment: process.env.NODE_ENV || 'development',
    minify: process.env.NODE_ENV === 'production',
    'public': 'dist',
    port: 3000,
    watch: process.env.NODE_ENV !== 'production'
  };
  module.exports = rc('arch', conf, null, lson.parse);
}).call(this);
