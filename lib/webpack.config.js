var merge = require('deep-extend');
var path = require('path');
var config = require('./get-config')();
var paths = config.paths;
var webpack = require('webpack');

var entryPoint = require.resolve(paths.app.abs);
var appModules = path.join(paths.app.abs, 'node_modules');
var archModules = path.join(paths.arch.abs, 'node_modules');

module.exports = {
  context: path.dirname(entryPoint),
  entry: [ './' + path.basename(entryPoint) ],
  output: {
    libraryTarget: 'var',
    library: 'Application',
    path: path.join(paths.app.abs, paths.public),
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
      },
      {
        test: /\.(?:js|jsx)$/,
        loader: 'babel-loader',
        exclude: /node_modules/
      }
    ]
  },
  plugins: [ new webpack.DefinePlugin({ 'process.env': JSON.stringify(merge(process.env, { ARCH_ENV: 'browser' })) })],
  resolve: {
    root: appModules,
    fallback: archModules,
    extensions: [ '', '.ls', '.js', '.jsx' ]
  },
  resolveLoader: {
    root: archModules,
    fallback: appModules
  }
}
