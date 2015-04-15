require! <[ bluebird ./routes ./cursor ./dom ./server-rendering ]>
require! './virtual-dom-utils': 'dom-utils'

{span} = dom

app-component = React.create-factory React.create-class do
  display-name: 'reflex-application'

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

init-app-state = (initial-state, route-context) ->
  cursor state: initial-state, route: route-context

observe-page-change = (root-tree, app-state) ->
  app-state.get \route .on-change ->
    # FIXME this is clearly a hack. We should figure out
    # how to do this when the rendering is done
    # which is after the set-state on the root component
    # is done.
    set-timeout ->
      {title} = dom-utils.route-metadata root-tree

      document.title = title
      window.scroll-to 0, 0
    , 0

module.exports =
  # define an application instance
  create: (app) ->
    do
      # start the application
      start: ->
        path = (location.pathname + location.search + location.hash)
        root-dom-node = document.get-element-by-id "application"
        server-state = JSON.parse root-dom-node.get-attribute 'data-reflex-app-state'

        route-set = app.routes!
        context = routes.resolve route-set, path

        app-state = if server-state
          cursor server-state
        else
          init-app-state app.get-initial-state!, context

        app.start app-state

        root-element = app-component app-state: app-state, routes: route-set
        root = React.render root-element, root-dom-node

        # re-render on app-state change
        app-state.on-change -> root.set-state app-state: app-state

        observe-page-change root, app-state
        routes.start app.routes!, app-state

      # render a particular route to string
      # returns a promise of [state, body]
      render: (path) ->
        route-set = app.routes!
        context = routes.resolve route-set, path
        app-state = init-app-state app.get-initial-state!, context

        transaction = app-state.start-transaction!
        app.start app-state

        root-element = app-component app-state: app-state, routes: route-set

        app-state.end-transaction transaction
        .then ->
          meta = server-rendering.route-metadata root-element, app-state
          [meta, app-state.deref!, React.render-to-string root-element]

      # process a form from a particular route and render to string
      # returns a promise of [state, body, location]
      process-form: (path, post-data) ->
        route-set = app.routes!
        context = routes.resolve route-set, path
        app-state = init-app-state app.get-initial-state!, context

        transaction = app-state.start-transaction!
        app.start app-state

        root-element = app-component app-state: app-state, routes: route-set

        location = server-rendering.process-form root-element, app-state, post-data, path
        app-state.end-transaction transaction
        .then ->
          meta = server-rendering.route-metadata root-element, app-state
          body = unless location then React.render-to-string root-element else null

          [meta, app-state.deref!, body, location]

