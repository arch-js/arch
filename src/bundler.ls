require! <[ webpack path webpack-dev-server fs ]>

{Obj, keys} = require 'prelude-ls'

get-default-config = (options) ->
  entry = require.resolve options.app-path

  browser-env = ^^process.env
  browser-env.ARCH_ENV = 'browser'
  browser-env = browser-env |> Obj.map JSON.stringify

  # Basic configuration
  config =
    entry: [ './' + path.basename entry ]

    context: path.dirname entry

    output:
      library-target: 'var'
      library: 'Application'
      path: path.join options.app-path, options.public-path
      filename: 'app.js'

    resolve:
      root: path.join options.app-path, 'node_modules'
      fallback: path.join options.arch-path, 'node_modules'
      extensions: [ '', '.ls', '.js', '.jsx' ]

    resolve-loader:
      root: path.join options.arch-path, 'node_modules'
      fallback: path.join options.app-path, 'node_modules'

    plugins: [ new webpack.DefinePlugin 'process.env': browser-env ]

    module:
      pre-loaders: [
        * test: /\.ls$/
          loader: 'livescript-loader'
          exclude: /node_modules/
        * test: /\.(?:js|jsx)$/
          loader: 'babel-loader'
          exclude: /node_modules/
      ]
      loaders: []
      post-loaders: []

  # Optimise for production.
  if process.env.NODE_ENV is 'production'
    config.plugins.push new webpack.optimize.DedupePlugin!
    config.plugins.push new webpack.optimize.UglifyJsPlugin!

  config

exports.bundle = (options, changed) ->
  conf-path = path.join options.app-path, 'webpack.config.js'
  fs.stat path.join(options.app-path, 'webpack.config.js'), (err, stats) ->
    if err
      config = get-default-config options
    else
      config = require conf-path

    # Enable HMR if watching.
    if options.watch
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
    if options.watch
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
        content-base: path.join options.app-path, options.public-path
        hot: true # Enable hot loading
        quiet: true
        no-info: true
        watch-delay: 200

      server.listen 3001, 'localhost'

    else
      # Run once if watch is false
      bundler.run (err, stats) ->
        console.log 'Bundled app.js'
