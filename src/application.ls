ReactServerRenderingTransaction = require 'react/lib/ReactServerRenderingTransaction'
ReactDefaultBatchingStrategy = require 'react/lib/ReactDefaultBatchingStrategy'
ReactUpdates = require 'react/lib/ReactUpdates'

require! <[ bluebird ./routes ./cursor ./dom ]>
{difference, filter, first, keys, Obj} = require 'prelude-ls'

test-utils = React.addons.TestUtils

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

# The core of isomorphic form processing.
# TODO probably extract to a separate module
process-form = (root-element, initial-state, post-data, path) ->
  # You could read this as switching React into server-only mode
  ReactDefaultBatchingStrategy.isBatchingUpdates = true
  ReactUpdates.injection.injectReconcileTransaction ReactServerRenderingTransaction
  ReactUpdates.injection.injectBatchingStrategy ReactDefaultBatchingStrategy
  console.log "Reconfigured react..."

  new bluebird (res, rej) ->
    # WARNING! Magic ahead
    # mount the component virtually, emulating server side rendering, but
    # getting the rendered instance back to be able to search it

    # use react server rendering transaction to get the markup tree safely
    transaction = ReactServerRenderingTransaction.get-pooled true

    instance = new root-element.type root-element.props
    instance.construct root-element

    try
      transaction.perform ->
        instance.mount-component "canBeAynthingWhee", transaction, 0
    finally
      ReactServerRenderingTransaction.release(transaction);

    forms = test-utils.find-all-in-rendered-tree instance, ->
      return it._tag is 'form'

    # FIXME ignore forms & inputs that are not in the post body
    input-names = keys post-data

    inputs = []
    form = forms
    |> filter (.props.action is path)
    |> find (form) ->
      inputs := test-utils.find-all-in-rendered-tree form, ->
        return it._tag in ['input', 'textarea', 'select'] and it.props.name in input-names

      return !empty inputs

    console.log "Form on-submit:", form.props.on-submit

    console.log "Inputs:"
    inputs |> each ->
      node = {}
      console.log "- name:", it.props.name

      console.log "triggering on change handler"

      # FIXME this is obviously not enough of a fake event, but it will do for now
      fake-event = target: value: post-data[it.props.name]

      it.props.on-change fake-event
      ReactUpdates.flushBatchedUpdates!

    console.log "triggering submit event"

    # FIXME this is obviously not enough of a fake event, but it will do for now
    fake-event = prevent-default: ->

    ReactUpdates.flushBatchedUpdates!
    form.props.on-submit fake-event

    ReactUpdates.flushBatchedUpdates!

    # end of magic

    state = initial-state.deref!
    body = React.render-to-string root-element

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

          # FIXME switch to promises and run both in paralel
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
            return res process-form root-element, initial-state, post-data, path unless route-init

            route-init initial-state, context, ->
              res process-form root-element, initial-state, post-data, path

