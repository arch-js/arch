{difference, filter, first, keys, Obj} = require 'prelude-ls'

ReactServerRenderingTransaction = require 'react/lib/ReactServerRenderingTransaction'
ReactDefaultBatchingStrategy = require 'react/lib/ReactDefaultBatchingStrategy'
ReactUpdates = require 'react/lib/ReactUpdates'

test-utils = React.addons.TestUtils

# FIXME is there a way to do this without state
# the form processing part is all synchronous, so
# we should be ok, but it's still nasty

redirect-location = null

configure-react = ->
  # You could read this as switching React into server-only mode
  ReactDefaultBatchingStrategy.isBatchingUpdates = true
  ReactUpdates.injection.injectReconcileTransaction ReactServerRenderingTransaction
  ReactUpdates.injection.injectBatchingStrategy ReactDefaultBatchingStrategy

render-tree = (element) ->
  # use react server rendering transaction to get the markup tree safely
  transaction = ReactServerRenderingTransaction.get-pooled true

  # simplified instantiateReactComponent (normal case for composite component)
  instance = new element.type element.props
  instance.construct element

  try
    transaction.perform ->
      instance.mount-component "canBeAynthingWhee", transaction, 0
  finally
    ReactServerRenderingTransaction.release(transaction);

  instance

extract-elements = (path, post-data, instance) ->
  input-names = keys post-data

  forms = test-utils.find-all-in-rendered-tree instance, ->
    return it._tag is 'form'

  inputs = []
  form = forms
  |> filter (.props.action is path)
  |> find (form) ->
    inputs := test-utils.find-all-in-rendered-tree form, ->
      return it._tag in ['input', 'textarea', 'select']

    return (inputs |> any -> it.props.name in input-names)

  [form, inputs]

# FIXME this is obviously not enough of a fake event, but it will do for now
# report ALL issues you find with this
fake-event = (element, opts = {}) ->
  target = if element.props.type in ['checkbox', 'radio']
    checked: !!opts.value
  else
    value: opts.value

  stop-propagation: ->
  prevent-default: ->
  target: target

change-inputs = (inputs, post-data) ->
  inputs |> each ->
    it.props.on-change (fake-event it, value: post-data[it.props.name])
    ReactUpdates.flushBatchedUpdates!

submit-form = (form) ->
  form.props.on-submit fake-event form
  ReactUpdates.flushBatchedUpdates!

# Processes a form server-side, returns a redirect location or null
# FIXME should we deal with the redirect in application.ls?
process-form = (root-element, initial-state, post-data, path) ->
  configure-react!
  reset-redirect!

  # WARNING! Magic ahead
  #
  # mount the component virtually, emulating server side rendering, but
  # getting the rendered instance back to be able to search it,
  # extract the correct form and input DOM components and trigger their
  # respective event handlers, which in turn updates app-state
  # finally, rerender the page

  instance = render-tree root-element

  [form, inputs] = extract-elements path, post-data, instance

  # trigger handlers
  change-inputs inputs, post-data
  submit-form form

  # end of magic

  return that if redirect-location

  null

reset-redirect = ->
  redirect-location := null

redirect = (path) ->
  redirect-location := path

module.exports =
  process-form: process-form
  redirect: redirect
