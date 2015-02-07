require! <[ express fs path jade bluebird body-parser ./bundler LiveScript ]>
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

  get = (req, res) ->
    console.log "GET ", req.original-url
    reflex-get app, req.original-url, options
    .then ->
      res.send it

  post = (req, res) ->
    post-data = req.body
    console.log "POST ", req.original-url, post-data

    reflex-post app, req.original-url, post-data, options
    .spread (status, headers, body) ->
      console.log "#status", headers
      res
        .status status
        .set headers
        .send body

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
  interp: reflex-interp
  /* end-test-exports */

reflex-get = (app, url, options) ->
  app.render url
  .spread (app-state, body) ->
    layout-render path.join(options.paths.layouts, 'default.html'), body, app-state, options

reflex-post = (app, url, post-data, options) ->
  app.process-form url, post-data
  .spread (app-state, body, location) ->
    if body
      layout-render path.join(options.paths.layouts, 'default.html'), body, app-state, options
      .then ->
        [200, {}, it]
    else
      # FIXME build a full URL for location to comply with HTTP
      bluebird.resolve [302, 'Location': location, ""];

reflex-interp = (template, body) ->
  template.to-string!.replace '{reflex-body}', body

reflex-render = (app, url, options) ->
  app.render url, (app-state, body) ->
    read-file path.join options.paths.layouts, 'default.html'
    .then ->
      bundle-path = if options.environment is 'development' then "http://localhost:3001/app.js" else "/#{options.paths.public}/app.js"
      reflex-interp it,
        __template public: options.paths.public, bundle: bundle-path, body: body, state: app-state
    .error !->
      throw new Error 'Template not found!'
