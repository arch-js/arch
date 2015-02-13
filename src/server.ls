require! <[ express fs path jade react bluebird ./bundler LiveScript ]>
{each, values, filter, find, flatten, map, first} = require 'prelude-ls'

__template = jade.compile-file (path.join __dirname, 'index.jade')
read-file = bluebird.promisify fs.read-file

defaults =
  environment: process.env.NODE_ENV or 'development'
  port: 3000
  paths:
    app:
      abs: path.resolve '.'
      rel: path.relative __dirname, path.resolve '.'
    layouts: 'app/layouts'
    reflex:
      abs: path.dirname require.resolve "reflex/package.json"
      rel: path.relative (path.resolve '.'), (path.dirname require.resolve "reflex/package.json")
    public: 'dist'

module.exports = (options=defaults) ->
  app = options.app or require options.paths.app.rel

  render = (req, res) ->
    console.log req.original-url
    return next! unless req.method is 'GET'
    reflex-render app, req.original-url, options
    .then ->
      res.send it

  start: (cb) ->
    server = express!
    .get '/favicon.ico', (req, res) -> res.redirect "/#{options.paths.public}/favicon.ico"
    .use "/#{options.paths.public}", express.static path.join(options.paths.app.abs, options.paths.public)
    .get '*', render

    # Bundle before server starts accepting requests.
    # .bundle takes a boolean of whether to watch and can take a callback which
    # allows you to hook into any watch changes.

    bundler.bundle options.paths, options.environment is 'development', (ids) ->
      done = []
      while id = first ids
        parents = require.cache |> values |> filter (-> !(it.id in done) and it.children |> find (.id is id)) |> flatten |> map (.id)
        done.push id
        parents |> each -> ids.push it
        ids.splice 0, 1

      done |> each -> delete require.cache[it]

      app := require options.paths.app.rel

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

reflex-render = (app, url, options) ->
  $ = app.start url
  [state, body] = $
  read-file path.join options.paths.layouts, 'default.html'
  .then ->
    bundle-path = if options.environment is 'development' then "http://localhost:3001/app.js" else "/#{options.paths.public}/app.js"
    reflex-interp it,
      __template public: options.paths.public, bundle: bundle-path, body: body, state: state
  .error !->
    throw new Error 'Template not found!'