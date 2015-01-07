require! <[ express fs path jade ]>

require! {
  bluebird: Promise
}

read-file = Promise.promisify fs.read-file

interpolate-template = (template, instantiation) ->

  template .to-string! .replace '{reflex-body}', instantiation

handle-method-get = (app, url, layouts-path) ->

  app.render url, (app-state, body) ->

    read-file path.join(layouts-path, 'default.html')
    .then (template) ->
      instantiation = jade .render-file "#{__dirname}/index.jade", body: body, state: app-state
      interpolate-template template, instantiation
    .error !->
      throw new Error 'Template not found'

run = (app, port, asset-path, layouts-path) ->

  console.log "Starting Reflex server..."

  server = express!

  console.log "Serving static assets from", asset-path, "on /dist"
  server.use '/dist', express.static asset-path

  server.get '*', (request, response) ->

    console.log "GET ", request.original-url

    handle-method-get app, request.original-url, layouts-path
    .then (template) !-> response.send template

  server.listen port
  console.log "Server running on port", port

module.exports =
  run: run
  handle-method-get: handle-method-get
