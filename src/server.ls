require! <[ express fs path jade liveify react browserify bluebird envify/custom uglifyify ]>

__template = jade.compile-file (path.join __dirname, 'index.jade')
read-file = bluebird.promisify fs.read-file

module.exports = (defaults, options={}) ->
  options = defaults if typeof defaults is "object"
  options.paths.app = path.relative __dirname, options.paths.app if options.paths and options.paths.app# Make the application path relative for requires.
  app = options.app or require options.paths.app
  bundle = void

  init = (req, res, next) ->
    req._reflex = res._reflex = {}
    next!

  render = (req, res, next) ->
    return next! unless req.method is 'GET'
    reflex-render app, req.original-url, options.paths.layouts
    .then ->
      res._reflex.body = it
      next!

  bundler = (req, res, next) ->
    res.set-header 'Content-Type', 'application/javascript'
    if bundle
      req._reflex.bundle = bundle
      next!
    else
      console.log 'Bundling app.js...'
      browserify!
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
      .require require.resolve(options.paths.app), expose: 'app'
      .bundle (err, data) ->
        console.log 'Done.'
        req._reflex.bundle = bundle := data
        next!

  start: (cb) ->
    server = express!
    .use init
    .get '/app.js', bundler
    .use '/dist', express.static
    .use render

    # Allow user to override the default server routes if they want to
    unless defaults is false
      server.get '/app.js', (req, res) ->
        res.send res._reflex.bundle
        res.end!

      server.get '*', (req, res) ->
        console.log 'GET', req.original-url
        res.send res._reflex.body
        res.end!

    if cb
      listener = server.listen options.port, (err) ->
        console.log 'App is listening on', listener.address!.port
        cb err, { server: server, listener: listener }
    else
      new bluebird (res, rej) ->
        listener = server.listen options.port, ->
          console.log 'App is listening on', listener.address!.port
          res server: server, listener: listener

  /* test-exports */
  interp: reflex-interp
  render: reflex-render
  /* end-test-exports */

reflex-interp = (template, body) ->
  template.to-string!.replace '{reflex-body}', body

reflex-render = (app, url, layouts) ->
  app.render url, (app-state, body) ->
    read-file path.join layouts, 'default.html'
    .then ->
      reflex-interp it,
        __template body: body, state: app-state
    .error !->
      throw new Error 'Template not found!'