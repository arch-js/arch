(function(){
  var path, fs, lson, ref$, filter, map, first, join, keys, parsers, parser, fpathRegex, filterConfigs, merge, initialConf, files, confFiles;
  path = require('path');
  fs = require('fs');
  lson = require('lson');
  ref$ = require('prelude-ls'), filter = ref$.filter, map = ref$.map, first = ref$.first, join = ref$.join, keys = ref$.keys;
  /* Map of parsers which take a file path and parse functions*/
  parsers = {
    js: function(it){
      return require(it);
    },
    ls: function(it){
      return require(it);
    }
  };
  parser = function(fname){
    return parsers[path.extname(fname).slice(1)](fname);
  };
  fpathRegex = new RegExp("arch.config.(?:" + join('|')(
  keys(
  parsers)) + ")$");
  filterConfigs = function(it){
    return fpathRegex.test(it);
  };
  merge = function(x, xs){
    return import$(x, xs);
  };
  initialConf = {
    appPath: process.env.arch_app_path || path.resolve('.'),
    archPath: process.env.arch_port || path.dirname(require.resolve('../package.json')),
    bundle: process.env.arch_bundle || true,
    debug: process.env.arch_debug || false,
    environment: process.env.arch_environment || process.env.NODE_ENV || 'development',
    minify: process.env.arch_minify || process.env.NODE_ENV === 'production',
    'public': process.env.arch_public || 'dist',
    port: process.env.arch_port || 3000,
    watch: process.env.arch_watch || process.env.NODE_ENV !== 'production'
  };
  files = fs.readdirSync(path.dirname('.'));
  confFiles = filter(filterConfigs, map(function(it){
    return path.resolve('.', it);
  }, files));
  if (confFiles.length > 1) {
    console.error('Multiple configs found. Please have one arch.config.ls or arch.config.js');
    module.exports = initialConf;
  } else {
    module.exports = merge(initialConf, parser(first(confFiles)));
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
