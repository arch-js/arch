require! <[ express ]>

run = (app, port, asset-path) ->
  console.log "Starting Reflex server..."

  server = express!

  server.set 'views', __dirname
  server.set 'view engine', 'jade'

  console.log "Serving static assets from", asset-path, "on /dist"
  server.use '/dist', express.static asset-path

  server.get '*', (request, response) ->
    console.log "GET ", request.original-url

    app.render request.original-url, (app-state, body) ->
      response.render 'index', body: body, state: app-state

  server.listen port
  console.log "Server running on port", port

module.exports = do
  run: run
