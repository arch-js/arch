require! <[ browserify watchify uglifyify liveify envify/custom path fs ]>

exports.bundle = (paths, watch) ->
  bundler = browserify do
    debug: process.env.NODE_ENV isnt 'production'
    cache: {}
    package-cache: {}
    full-paths: watch
  .transform liveify
  .transform do
    compress:
      sequences: true
      dead_code: true
      conditionals: true
      booleans: true
      unused: true
      if_return: true
      join_vars: true
      drop_console: true
    global: true
    uglifyify
  .transform custom REFLEX_ENV: 'browser'
  .require require.resolve(paths.app), expose: 'app'

  make-bundle = ->
    console.log 'bundling app.js...'
    b = bundler.bundle!
    b.on 'error', console.error
    b.pipe fs.create-write-stream path.join(paths.public, 'app.js')

  if watch
    bundler = watchify bundler
    bundler.on 'update', make-bundle

  make-bundle!