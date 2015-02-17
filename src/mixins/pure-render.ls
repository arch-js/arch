{keys, each} = require 'prelude-ls'
require! 'deep-equal'

eq = (a, b) ->
  return false unless a and b
  if is-cursor a and is-cursor b
    # Both are cursors, compare data equality
    cursor-eq a, b
  else
    mutable-eq a, b

mutable-eq = (a, b) ->
  deep-equal a, b

cursor-eq = (a, b) ->
  a.eq b

is-cursor = ->
  return it and typeof it.deref is 'function' and typeof it.eq is 'function'

module.exports =
  should-component-update: (next-props, next-state) ->
    for key, prop of @props
      return true unless eq prop, next-props[key]
    for key, state of @state
      return true unless eq state, next-state[key]
    false