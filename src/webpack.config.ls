require! {
  'deep-extend'
  path
  './default-config': 'config'
  webpack
}

paths = config.paths;
entry-point = require.resolve paths.app.abs
app-modules = path.join paths.app.abs, 'node_modules'
arch-modules = path.join paths.arch.abs, 'node_modules'

module.exports = (sever-options) ->
  context: path.dirname entry-point
  entry: [ './' + path.basename entry-point ]
  output:
    library-target: 'var'
    library: 'Application'
    path: path.join paths.app.abs, paths.public
    filename: 'app.js'
  module:
    loaders: []
    post-loaders: []
    pre-loaders:
      * test: /\.ls$/
        loader: 'livescript-loader'
        exclude: /node_modules/
      * test: /\.(?:js|jsx)$/
        loader: 'babel-loader'
        exclude: /node_modules/
  plugins: [ new webpack.DefinePlugin('process.env': JSON.stringify(deep-extend process.env, ARCH_ENV: 'browser')) ]
  resolve:
    root: app-modules
    fallback: arch-modules
    extensions: [ '', '.ls', '.js', '.jsx' ]
  resolveLoader:
    root: arch-modules
    fallback: app-modules