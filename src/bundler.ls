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
        * test: /.*/
          loader: 'envify-loader'
      ]

  # Optimise for production.
  if process.env.NODE_ENV is 'production'
    config.plugins.push new webpack.optimize.DedupePlugin!
    config.plugins.push new webpack.optimize.UglifyJsPlugin!

  # Run the bundle
  bundler = webpack config

  # Bundle or watch.
  unless watch
    bundler.run (err, stats) ->
      console.log err if err
      console.log 'Bundled app.js'
  else
    end = null
    bundler.watch 200, (err, stats) ->
      if end
        diff = stats.compilation.file-timestamps |> Obj.filter (-> it > end) |> keys
        if diff.length > 0
          changed diff
          console.log 'Rebundled:'
          console.log diff
      else
        console.log 'Bundled app.js'
      end := stats.end-time

# require! <[ browserify aliasify watchify uglifyify liveify envify/custom path fs ]>

# {map, join} = require 'prelude-ls'

# # Full-paths will be enabled when watch is enabled (requirement for watchify).
# # Not a problem in production but it looks super unsafe if you inspect sources in your
# # browser's developer tools

# exports.bundle = (paths, watch, changed) ->
#   bundler = browserify do
#     debug: watch
#     cache: {}
#     package-cache: {}
#     full-paths: watch
#   .require require.resolve(paths.app), expose: 'app'
#   .transform liveify
#   # Aliasify so that reflex and user app use the same module (otherwise bundle ships multiple Reacts... not good.)
#   .transform global: true, aliasify.configure do
#     aliases:
#       react: './node_modules/react'
#     config-dir: path.resolve '.'
#     applies-to:
#       include-extensions: <[ .ls .js ]>
#   .transform global: true, custom REFLEX_ENV: 'browser'
#   .transform do
#     compress:
#       sequences: true
#       dead_code: true
#       conditionals: true
#       booleans: true
#       unused: true
#       if_return: true
#       join_vars: true
#       drop_console: false
#     global: true
#     uglifyify

#   make-bundle = ->
#     b = bundler.bundle!
#     b.on 'error', console.error
#     b.pipe fs.create-write-stream path.join(paths.public, 'app.js')

#   if watch
#     bundler = watchify bundler
#     bundler.on 'update', (ids) ->
#       console.log "Rebuilding #{path.join(paths.public, 'app.js')}"
#       changed ids if typeof changed isnt 'undefined'
#       make-bundle!

#   make-bundle!