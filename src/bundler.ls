require! <[ browserify watchify uglifyify liveify envify/custom path fs ]>

# Full-paths will be enabled when watch is enabled (requirement for watchify).
# Not a problem in production but it looks super unsafe if you inspect sources in your
# browser's developer tools

exports.bundle = (paths, watch, changed) ->
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
      drop_console: false
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
    bundler.on 'update', ->
      changed! if typeof changed isnt 'undefined'
      make-bundle!

  make-bundle!