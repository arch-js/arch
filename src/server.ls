require! <[ express fs path jade react bluebird ./bundler LiveScript ]>
{each, values, filter, find, flatten, map} = require 'prelude-ls'

__template = jade.compile-file (path.join __dirname, 'index.jade')
read-file = bluebird.promisify fs.read-file

defaults =
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
    return next! unless req.method is 'GET'
    reflex-render app, req.original-url, options.paths
    .then ->
      res.send it

  start: (cb) ->
    server = express!
    .use "/#{options.paths.public}", express.static path.join(options.paths.app.abs, options.paths.public)
    .get '*', render

    # Bundle before server starts accepting requests.
    # .bundle takes a boolean of whether to watch and can take a callback which
    # allows you to hook into any watch changes.

    bundler.bundle options.paths, (process.env.NODE_ENV isnt 'production'), (ids) ->
      done = []
      until ids.length is 0
        ids |> each (id) ->
          parents = require.cache |> values |> filter (-> !(it.id in done) and it.children |> find (.id is id)) |> flatten |> map (.id)
          done.push id
          ids := parents

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

reflex-render = (app, url, paths) ->
  app.render url, (app-state, body) ->
    read-file path.join paths.layouts, 'default.html'
    .then ->
      reflex-interp it,
        __template public: paths.public, body: body, state: app-state
    .error !->
      throw new Error 'Template not found!'