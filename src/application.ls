react = require 'react/addons'
require! <[ ./routes ./cursor ./dom ]>
global import require 'prelude-ls'

test-utils = react.addons.TestUtils

{span} = dom
app-component = react.create-factory react.create-class do
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

# The core of isomorphic form processing.
# TODO probably extract to a separate module
process-form = (root-component, initial-state, post-data, done) ->
  state = initial-state.deref!
  body = "Processing form for post-data: #{JSON.stringify(post-data)} <br/>Resulting app-state: #{JSON.stringify(state)}"

  results = test-utils.findAllInRenderedTree root-component, ->
    console.log "Test", it.props.class-name
    true

  console.log "find all results", results

  done [state, body, null]

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
        root = react.render root-component, root-element

        app-state.on-change -> root.set-state app-state: app-state
        routes.start config.routes!, root, app-state

      # render a particular route to string
      render: (path, cbk) ->
        route-config = config.routes!
        initial-state = cursor config.get-initial-state!

        [route-component, context, route-init] = routes.resolve path, route-config

        root-component = app-component initial-state: initial-state, component: route-component, context: context

        # FIXME switch to promises and run both in paralel
        config.start initial-state, ->
          return (cbk initial-state.deref!, react.render-to-string root-component) unless route-init

          route-init initial-state, context, ->
            cbk initial-state.deref!, react.render-to-string root-component

      # process a form from a particular route and render to string
      process-form: (path, post-data, cbk) ->
        route-config = config.routes!
        initial-state = cursor config.get-initial-state!

        [route-component, context, route-init] = routes.resolve path, route-config
        return (cbk initial-state.deref!, "404") unless route-component

        root-component = app-component initial-state: initial-state, component: route-component, context: context

        config.start initial-state, ->
          unless route-init
            return process-form root-component, initial-state, post-data, (result) ->
              cbk ...result

          route-init initial-state, context, ->
            process-form root-component, initial-state, post-data, (result) ->
              cbk ...result

