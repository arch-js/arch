require! <[ express fs path jade bluebird body-parser ./bundler LiveScript babel/register ]>
{each, values, filter, find, flatten, map, first} = require 'prelude-ls'

defaults =
  environment: process.env.NODE_ENV or 'development'
  port: 3000
  paths:
    app:
      abs: path.resolve '.'
      rel: path.relative __dirname, path.resolve '.'
    reflex:
      abs: path.dirname require.resolve "../package.json"
      rel: path.relative (path.resolve '.'), (path.dirname require.resolve "../package.json")
    public: 'dist'

module.exports = (options) ->
  options = ^^defaults import options
  app = options.app or require options.paths.app.rel

  get = (req, res) ->
    console.log "GET", req.original-url
    reflex-get app, req.original-url, options
    .spread (status, headers, body) ->
      res.status status .set headers .send body

  post = (req, res) ->
    console.log "POST", req.original-url, req.body
    reflex-post app, req.original-url, req.body, options
    .spread (status, headers, body) ->
      res.status status .set headers .send body

  start: (cb) ->
    server = express!
    .use "/#{options.paths.public}", express.static path.join(options.paths.app.abs, options.paths.public)
    .use body-parser.urlencoded extended: false
    .get '*', get
    .post '*', post

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
  get: reflex-get
  post: reflex-post
  render: layout-render
  /* end-test-exports */

reflex-get = (app, url, options) ->
  app.render url
  .spread (meta, app-state, body) ->
    html = layout-render meta, body, app-state, options
    [200, {}, html]

reflex-post = (app, url, post-data, options) ->
  app.process-form url, post-data
  .spread (meta, app-state, body, location) ->
    # FIXME build a full URL for location to comply with HTTP
    return [302, 'Location': location, ""] unless body

    html = layout-render meta, body, app-state, options
    [200, {}, html]

__template = jade.compile-file (path.join __dirname, 'index.jade')

layout-render = (meta, body, app-state, options) ->
  bundle-path = if options.environment is 'development' then "http://localhost:3001/app.js" else "/#{options.paths.public}/app.js"
  reflex-body = __template public: options.paths.public, bundle: bundle-path, body: body, state: app-state

  {layout, title} = meta
  layout body: reflex-body, title: title
