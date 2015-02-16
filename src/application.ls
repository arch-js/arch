react = require 'react/addons'
server-rendering-transaction = require 'react/lib/ReactServerRenderingTransaction'
require! <[ bluebird ./routes ./cursor ./dom ]>
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
process-form = (root-element, initial-state, post-data) ->
  new bluebird (res, rej) ->
    state = initial-state.deref!
    body = "Processing form for post-data: #{JSON.stringify(post-data)} <br/>Resulting app-state: #{JSON.stringify(state)}"

    # WARNING! Magic ahead
    # mount the component virtually, emulating server side rendering, but
    # getting the rendered instance back to be able to search it

    # use react server rendering transaction to get the markup tree safely
    transaction = server-rendering-transaction.get-pooled true

    instance = new root-element.type root-element.props
    instance.construct root-element

    try
      transaction.perform ->
        instance.mount-component "canBeAynthingWhee", transaction, 0
    finally
      server-rendering-transaction.release(transaction);

    elements = test-utils.find-all-in-rendered-tree instance, ->
      return it._tag in ['input', 'form']

    console.log "Form elements: ", elements
    # end of magic

    res [state, body, null]

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

      # render a particular route to string, returns a promise
      render: (path) ->
        new bluebird (res, rej) ->
          route-config = config.routes!
          initial-state = cursor config.get-initial-state!

          [route-component, context, route-init] = routes.resolve path, route-config

          root-component = app-component initial-state: initial-state, component: route-component, context: context

          # FIXME switch to promises and run both in paralel
          config.start initial-state, ->
            return res [initial-state.deref!, react.render-to-string root-component] unless route-init

            route-init initial-state, context, ->
              res [initial-state.deref!, react.render-to-string root-component]

      # process a form from a particular route and render to string
      # returns a promise of [state, body, location]
      process-form: (path, post-data) ->
        new bluebird (res, rej) ->
          route-config = config.routes!
          initial-state = cursor config.get-initial-state!

          [route-component, context, route-init] = routes.resolve path, route-config

          root-element = app-component initial-state: initial-state, component: route-component, context: context

          config.start initial-state, ->
            return res process-form root-element, initial-state, post-data unless route-init

            route-init initial-state, context, ->
              res process-form root-element, initial-state, post-data

