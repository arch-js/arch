require! <[ webpack path ]>

{Obj, keys} = require 'prelude-ls'

exports.bundle = (paths, watch, changed) ->
  entry = require.resolve paths.app.abs

  # Basic configuration
  config =
    entry: './' + path.basename entry

    context: path.dirname entry

    output:
      library-target: 'var'
      library: 'Application'
      path: path.join paths.app.abs, paths.public
      filename: 'app.js'

    resolve:
      extensions: [ '', '.ls', '.js', '.jsx' ]
      root: path.join paths.app.abs, 'node_modules'
      fallback: path.join paths.reflex.abs, 'node_modules'

    resolve-loader:
      root: path.join paths.reflex.abs, 'node_modules'
      fallback: path.join paths.app.abs, 'node_modules'

    plugins: []

    module:
      pre-loaders: [
        * test: /\.ls$/
          loader: 'livescript-loader'
      ]
      loaders: [
        * test: /\.(?:ls|js|jsx)$/
          loader: 'envify-loader'
      ]
      post-loaders: []

  # Optimise for production.
  if process.env.NODE_ENV is 'production'
    config.plugins.push new webpack.optimize.DedupePlugin!
    config.plugins.push new webpack.optimize.UglifyJsPlugin!

  # Initialise the bundle
  bundler = webpack config

  if watch # Start a watcher

    # Add a callback to server, passing changed files, to reload app code server-side.
    last-build = null
    bundler.plugin 'done', (stats) ->
      diff = stats.compilation.file-timestamps |> Obj.filter (> last-build) |> keys
      changed diff
      last-build := stats.end-time

    bundler.plugin 'failed', (err) ->
      console.log err

    # Start the watcher
    bundler.watch 200, (err, stats) ->
      console.log 'Bundled app.js'

  else # Run once
    bundler.run (err, stats) ->
      console.log 'Bundled app.js'
