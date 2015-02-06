require! <[ browserify aliasify watchify uglifyify liveify envify/custom path fs ]>

{map, join} = require 'prelude-ls'

# Full-paths will be enabled when watch is enabled (requirement for watchify).
# Not a problem in production but it looks super unsafe if you inspect sources in your
# browser's developer tools

exports.bundle = (paths, watch, changed) ->
  bundler = browserify do
    debug: watch
    cache: {}
    package-cache: {}
    full-paths: watch
  .require require.resolve(paths.app), expose: 'app'
  .transform liveify
  # Aliasify so that reflex and user app use the same module (otherwise bundle ships multiple Reacts... not good.)
  .transform global: true, aliasify.configure do
    aliases:
      react: './node_modules/react'
    config-dir: path.resolve '.'
    applies-to:
      include-extensions: <[ .ls .js ]>
  .transform global: true, custom REFLEX_ENV: 'browser'
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

  make-bundle = ->
    b = bundler.bundle!
    b.on 'error', console.error
    b.pipe fs.create-write-stream path.join(paths.public, 'app.js')

  if watch
    bundler = watchify bundler
    bundler.on 'update', (ids) ->
      console.log "Rebuilding #{path.join(paths.public, 'app.js')}"
      changed ids if typeof changed isnt 'undefined'
      make-bundle!

  make-bundle!