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
      that context: @state.context, app-state: @state.app-state
    else
      span "Page not found."

module.exports =
  # define an application instance
  create: (config) ->
    do
      # start the application
      start: ->
        route-config = config.routes!
        root-element = document.get-element-by-id "application"
        initial-state = JSON.parse root-element.get-attribute 'data-reflex-app-state'

        path = (location.pathname + location.search + location.hash)

        [route-component, context, route-init] = routes.resolve path, route-config
        app-state = cursor (initial-state or config.get-initial-state!)
        config.start app-state, (->)

        root-component = app-component initial-state: app-state, component: route-component, context: context
        root = React.render root-component, root-element

        app-state.on-change -> root.set-state app-state: app-state
        routes.start config.routes!, root, app-state

      # render a particular route to string, returns a promise
      render: (path) ->
        new bluebird (res, rej) ->
          route-config = config.routes!
          initial-state = cursor config.get-initial-state!

          [route-component, context, route-init] = routes.resolve path, route-config

          root-component = app-component initial-state: initial-state, component: route-component, context: context

          config.start initial-state, ->
            return res [initial-state.deref!, React.render-to-string root-component] unless route-init

            route-init initial-state, context, ->
              res [initial-state.deref!, React.render-to-string root-component]

      # process a form from a particular route and render to string
      # returns a promise of [state, body, location]
      process-form: (path, post-data) ->
        new bluebird (res, rej) ->
          route-config = config.routes!
          initial-state = cursor config.get-initial-state!

          [route-component, context, route-init] = routes.resolve path, route-config

          root-element = app-component initial-state: initial-state, component: route-component, context: context

          config.start initial-state, ->
            return res server-rendering.process-form root-element, initial-state, post-data, path unless route-init

            route-init initial-state, context, ->
              res server-rendering.process-form root-element, initial-state, post-data, path

