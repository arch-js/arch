require! <[ bluebird ./cursor ./dom ./routes ./server-rendering cookie ]>
require! './virtual-dom-utils': 'dom-utils'
unesc = require 'lodash/string/unescape'

{keys, each, Obj, map, reject} = require 'prelude-ls'

{span} = dom

app-component = React.create-factory React.create-class do
  display-name: 'arch-application'

  get-initial-state: ->
    app-state: @props.app-state

  lookup-component: ->
    route = @state.app-state.get \route .deref!
    routes.get-component @props.routes, route.component-id

  render: ->
    component = @lookup-component!
    if component
      React.create-element that, app-state: @state.app-state
    else
      # FIXME make this user editable
      span "Page not found."

init-app-state = (app-state = {}, initial-state, route-context, cookies) ->
  cursor (app-state import state: initial-state, route: route-context, cookies: cookies)

observe-page-change = (root-tree, app-state) ->
  app-state.get \route .on-change (route) ->
    # FIXME this is clearly a hack. We should figure out
    # how to do this when the rendering is done
    # which is after the set-state on the root component
    # is done.
    set-timeout ->
      {title} = dom-utils.route-metadata root-tree
      document.title = title
      if el = document.get-element-by-id route.hash
        # scroll to element if hash target and hash target found
        window.scroll-to 0, (el.get-bounding-client-rect!.top - document.body.get-bounding-client-rect!.top)
      else
        # scroll to top if no hash target or not found
        window.scroll-to 0, 0
    , 0

module.exports =
  # define an application instance
  create: (app) ->
    do
      # start the application on the client
      start: ->
        route-set = app.routes!
        path = (location.pathname + location.search + location.hash)

        root-dom-node = document.get-element-by-id "application"

        # Initialise app state

        state-node = document.get-element-by-id "arch-state"
        if state-node then server-state = JSON.parse unesc(state-node.text)

        app-state = if server-state
          cursor server-state
        else
          init-app-state {}, app.get-initial-state!, {}, {}

        # Boot the app

        app.start app-state

        unless server-state
          app-state.get 'cookies' .update ->
            cookie.parse document.cookie
            |> keys
            |> map (k) -> cookie.serialize(k, client-cookies[k])

          app-state.get 'route' .update -> routes.resolve(route-set, path)

        # Mount the root component

        root-element = app-component app-state: app-state, routes: route-set
        root = React.render root-element, root-dom-node

        # Whenever app state changes re-render

        app-state.get 'cookies' .on-change (cookies) ->
          cookies |> each (ck) ->
            document.cookie = ck;

        app-state.on-change -> root.set-state app-state: app-state

        # Rerender with any post-mount changes applied.

        root = React.render root-element, root-dom-node

        # Set up SPA navigation

        observe-page-change root, app-state
        routes.start app.routes!, app-state

      # render a particular route to string
      # returns a promise of [state, body]
      render: (req, res) ->
        path = req.original-url
        route-set = app.routes!
        client-cookies = cookie.parse (req.headers.cookie || "")
        parsed-cookies = client-cookies
          |> keys
          |> map (k) -> cookie.serialize(k, client-cookies[k])

        app-state = init-app-state req.app-state, app.get-initial-state!, null, []

        transaction = app-state.start-transaction!

        # Don't overwrite cookies that already exist, only ones that are set while rendering

        app-state.get 'cookies' .on-change (cookies) ->
          newCookies = cookies |> reject (-> it in parsed-cookies);
          res.set 'Set-Cookie', newCookies

        # Boot the app

        app.start app-state
        app-state.get 'cookies' .update -> parsed-cookies
        app-state.get 'route' .update -> routes.resolve(route-set, path)
        root-element = app-component app-state: app-state, routes: route-set

        app-state.end-transaction transaction
        .then ->
          meta = server-rendering.route-metadata root-element, app-state
          body = unless (location = server-rendering.get-redirect!) and location isnt path then React.render-to-string root-element else null
          server-rendering.reset-redirect!
          [meta, app-state.deref!, body, location]

      # process a form from a particular route and render to string
      # returns a promise of [state, body, location]
      process-form: (req, res) ->
        var root-element
        path = req.original-url

        client-cookies = cookie.parse (req.headers.cookie || "")
        parsed-cookies = client-cookies
          |> keys
          |> map (k) -> cookie.serialize(k, client-cookies[k])

        route-set = app.routes!
        app-state = init-app-state req.app-state, app.get-initial-state!, null, []

        app-state.get 'cookies' .on-change (cookies) ->
          res.set('Set-Cookie', cookies);

        transaction = app-state.start-transaction!

        # Boot the app

        app.start app-state
        app-state.get 'cookies' .update -> parsed-cookies
        app-state.get 'route' .update -> routes.resolve(route-set, path)

        # Start form processing after initial render

        app-state.end-transaction transaction
        .then ->
          form-processing-transaction = app-state.start-transaction!

          root-element := app-component app-state: app-state, routes: route-set

          # Process the form data

          server-rendering.process-form root-element, app-state, req.body, path
          return app-state.end-transaction form-processing-transaction
        .then ->
          meta = server-rendering.route-metadata root-element, app-state
          body = unless (location = server-rendering.get-redirect!) and location isnt path then React.render-to-string root-element else null

          [meta, app-state.deref!, body, location]
