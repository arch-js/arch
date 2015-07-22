require! <[ express fs path jade bluebird body-parser ./bundler livescript cookie-parser babel/register xss-filters ]>


{each, values, filter, find, flatten, map, first} = require 'prelude-ls'

defaults =
  arch-path: path.dirname path.resolve './node_modules/arch'
  app-path: path.dirname path.resolve './package.json'
  bundle: true
  bundle-path: 'http://localhost:3001/app.js'
  environment: process.env.NODE_ENV or 'development'
  port: 3000
  public-path: 'dist'
  watch: true

module.exports = (options) ->
  options = ^^defaults import options
  app = require options.app-path

  server = express!
    .use "/#{options.public-path}", express.static path.join(options.app-path, options.public-path)
    .use body-parser.urlencoded extended: false
    .use cookie-parser!

  get = (req, res) ->
    console.log "GET", req.original-url
    arch-get app, req, res, options
    .spread (status, headers, body) ->
      res.status status .set headers .send body

  post = (req, res) ->
    console.log "POST", req.original-url
    arch-post app, req, res, options
    .spread (status, headers, body) ->
      res.status status .set headers .send body

  inst: server
  start: (cb) ->
    server
      .get '*', get
      .post '*', post

    start-server = ->
      if cb
        listener = server.listen options.port, (err) ->
          console.log 'App is listening on', listener.address!.port
          cb err, { server: server, listener: listener }
      else
        new bluebird (res, rej) ->
          listener = server.listen options.port, ->
            console.log 'App is listening on', listener.address!.port
            res server: server, listener: listener

    # Bundle before server starts accepting requests.
    # .bundle takes a boolean of whether to watch and can take a callback which
    # allows you to hook into any watch changes.

    if (options.bundle)
      bundler.bundle options, (ids) ->
        console.log('bundled');
        done = []
        while id = first ids
          parents = require.cache |> values |> filter (-> !(it.id in done) and it.children |> find (.id is id)) |> flatten |> map (.id)
          done.push id
          parents |> each -> ids.push it
          ids.splice 0, 1

        done |> each -> delete require.cache[it]

        try
          app := require options.app-path
        catch
          console.error 'Error in changed files when restarting server'

        start-server!
    else
      start-server!

  /* test-exports */
  get: arch-get
  post: arch-post
  render: layout-render
  /* end-test-exports */

arch-get = (app, req, res, options) ->
  app.render req, res
  .spread (meta, app-state, body, location) ->
    return [302, 'Location': location, ""] unless body

    html = layout-render meta, body, app-state, options
    [200, {}, html]

arch-post = (app, req, res, options) ->
  app.process-form req, res
  .spread (meta, app-state, body, location) ->
    # FIXME build a full URL for location to comply with HTTP
    return [302, 'Location': location, ""] unless body

    html = layout-render meta, body, app-state, options
    [200, {}, html]

__template = jade.compile-file (path.join __dirname, 'index.jade')

layout-render = (meta, body, app-state, options) ->
  arch-body = __template public: options.public-path, bundle: options.bundle-path, body: body, state: (app-state |> JSON.stringify |> xss-filters.inHTMLData)

  {layout, title} = meta
  layout body: arch-body, title: title
