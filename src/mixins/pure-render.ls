{keys, each} = require 'prelude-ls'

module.exports =
  should-component-update: (next-props, next-state) ->
    console.log @props.state.deref!, next-props.state.deref!
    # Shallow compare props and state existence and identity from its cursor.
    for key, prop of @props
      return true unless key is 'children' or next-props[key] and prop.eq next-props[key]
    for key, state of @state
      return true unless next-state[key] and state.eq next-state[key]
    false