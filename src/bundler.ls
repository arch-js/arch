require! <[ webpack path webpack-dev-server ]>
baseConfig = require './webpack.config.js'

{Obj, keys} = require 'prelude-ls'

exports.bundle = (paths, watch, changed) ->
  config = baseConfig
  # Optimise for production.
  if process.env.NODE_ENV is 'production'
    config.plugins.push new webpack.optimize.DedupePlugin!
    config.plugins.push new webpack.optimize.UglifyJsPlugin!

  # Enable HMR if watching.
  if watch
    config.entry.unshift 'webpack/hot/dev-server'
    config.entry.unshift 'webpack-dev-server/client?http://localhost:3001'
    config.output.public-path = 'http://localhost:3001/'
    config.module.loaders.push do
      test: /\.(?:js|jsx|ls)$/
      loader: 'react-hot'
      exclude: /node_modules/
    config.plugins.push new webpack.HotModuleReplacementPlugin!
    config.plugins.push new webpack.NoErrorsPlugin!

  # Initialise the bundle
  bundler = webpack config

  # Just bundle or watch + serve via webpack-dev-server
  if watch

    # Add a callback to server, passing changed files, to reload app code server-side.
    last-build = null
    bundler.plugin 'done', (stats) ->
      diff = stats.compilation.file-timestamps |> Obj.filter (> last-build) |> keys
      changed diff
      last-build := stats.end-time

    bundler.plugin 'error', (err) ->
      console.log err

    # Start the webpack dev server
    server = new webpack-dev-server bundler, do
      filename: 'app.js'
      content-base: path.join paths.app.abs, paths.public
      hot: true # Enable hot loading
      quiet: true
      no-info: false
      watch-delay: 200
      headers:
        'Access-Control-Allow-Origin': '*'

    server.listen 3001, 'localhost'

  else
    # Run once if watch is false
    bundler.run (err, stats) ->
      console.log 'Bundled app.js'
