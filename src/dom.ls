require! <[ ./cursor ]>
{first, tail, each, keys, is-type, empty} = require 'prelude-ls'

_cursor = cursor []
is-cursor = -> # TODO: better checking for this...
  return (difference (it |> keys), (_cursor |> keys)).length is 0

obj-is-el = ->
  return true if is-type 'Array', it
  return React.is-valid-element it

is-node = ->
  switch typeof it
  | 'number' => true
  | 'string' => true
  | 'boolean' => !it
  | 'object' => obj-is-el it
  | otherwise false

component = (el, args) ->
  props = first args or {}
  children = tail args

  if is-node props
    children = args
    props = {}

  props.children =
    if children? and not empty children
      if children.length is 1 then children[0] else children

  React.create-element el, props

dom = (el) ->
  (...args) ->
    component el, args

React.DOM |> keys |> each ->
  dom[it] = dom it

module.exports = dom
