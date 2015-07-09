(function(){
  var deepExtend, path, config, webpack, paths, entryPoint, appModules, archModules;
  deepExtend = require('deep-extend');
  path = require('path');
  config = require('./default-config');
  webpack = require('webpack');
  paths = config.paths;
  entryPoint = require.resolve(paths.app.abs);
  appModules = path.join(paths.app.abs, 'node_modules');
  archModules = path.join(paths.arch.abs, 'node_modules');
  module.exports = function(severOptions){
    return {
      context: path.dirname(entryPoint),
      entry: ['./' + path.basename(entryPoint)],
      output: {
        libraryTarget: 'var',
        library: 'Application',
        path: path.join(paths.app.abs, paths['public']),
        filename: 'app.js'
      },
      module: {
        loaders: [],
        postLoaders: [],
        preLoaders: [
          {
            test: /\.ls$/,
            loader: 'livescript-loader',
            exclude: /node_modules/
          }, {
            test: /\.(?:js|jsx)$/,
            loader: 'babel-loader',
            exclude: /node_modules/
          }
        ]
      },
      plugins: [new webpack.DefinePlugin({
        'process.env': JSON.stringify(deepExtend(process.env, {
          ARCH_ENV: 'browser'
        }))
      })],
      resolve: {
        root: appModules,
        fallback: archModules,
        extensions: ['', '.ls', '.js', '.jsx']
      },
      resolveLoader: {
        root: archModules,
        fallback: appModules
      }
    };
  };
}).call(this);
