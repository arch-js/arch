require! <[ express fs path jade react bluebird ./bundler hotload ]>

__template = jade.compile-file (path.join __dirname, 'index.jade')
read-file = bluebird.promisify fs.read-file

module.exports = (defaults, options={}) ->
  options = defaults if typeof defaults is "object"
  app = options.app or require path.relative(__dirname, options.paths.app)

  render = (req, res) ->
    return next! unless req.method is 'GET'
    reflex-render app, req.original-url, options.paths.layouts
    .then ->
      res.send it

  start: (cb) ->
    server = express!
    .use "/#{options.paths.public}", express.static path.join(options.paths.app, options.paths.public)
    .get '*', render

    # Bundle before server starts accepting requests.
    # .bundle takes a boolean of whether to watch and can take a callback which
    # allows you to hook into any watch changes.
    # TODO: Figure out a way to reload server code correctly, at the moment this hotload module
    # only reloads app.ls
    # Potentially just use a child process.
    bundler.bundle options.paths, true, ->
      app := hotload path.relative(__dirname, options.paths.app)

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