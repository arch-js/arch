require! <[ bluebird ./routes ./cursor ./dom ./server-rendering ]>
{span} = dom

app-component = React.create-factory React.create-class do
  display-name: 'reflex-application'

  get-initial-state: ->
    component: @props.component
    context: @props.context
    app-state: @props.initial-state

  render: ->
    if @state.component
      React.create-element that, context: @state.context, app-state: @state.app-state
    else
      span "Page not found."

module.exports =
  # define an application instance
  create: (config) ->
    do
      # start the application
      start: ->
        path = (location.pathname + location.search + location.hash)
        root-dom-node = document.get-element-by-id "application"

        server-state = JSON.parse root-dom-node.get-attribute 'data-reflex-app-state'
        initial-state = cursor (server-state or config.get-initial-state!)

        [route-component, context, _] = routes.resolve path, config.routes!
        root-element = app-component initial-state: initial-state, component: route-component, context: context

        config.start initial-state

        root = React.render root-element, root-dom-node

        initial-state.on-change -> root.set-state app-state: initial-state
        routes.start config.routes!, root, initial-state

      # render a particular route to string
      # returns a promise of [state, body]
      render: (path) ->
        app-state = cursor config.get-initial-state!

        [route-component, context, route-init] = routes.resolve path, config.routes!
        root-element = app-component initial-state: app-state, component: route-component, context: context

        transaction = app-state.start-transaction!

        config.start app-state
        route-init app-state, context if route-init

        app-state.end-transaction transaction
        .then ->
          [app-state.deref!, React.render-to-string root-element]

      # process a form from a particular route and render to string
      # returns a promise of [state, body, location]
      process-form: (path, post-data) ->
        app-state = cursor config.get-initial-state!

        [route-component, context, route-init] = routes.resolve path, config.routes!
        root-element = app-component initial-state: app-state, component: route-component, context: context

        transaction = app-state.start-transaction!

        config.start app-state
        route-init app-state, context if route-init

        location = server-rendering.process-form root-element, app-state, post-data, path

        app-state.end-transaction transaction
        .then ->
          body = unless location then React.render-to-string root-element else null

          [app-state.deref!, body, location]

