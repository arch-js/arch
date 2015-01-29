require! <[ react path ]>
require! './dom'

factorify = (klass) ->
  dom klass

factorify-all = (obj) ->
  obj |> Obj.map ->
    dom it

create-component = (spec) ->
  dom react.create-class spec

# Core framework namespace bundling together individual modules
module.exports =
  application: require './application'
  routes: require './routes'
  cursor: require './cursor'
  dom: dom

  # move to util?
  create-component: create-component
  factorify: factorify
  factorify-all: factorify-all