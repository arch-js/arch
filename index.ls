require! <[ react path ]>

factorify = (klass) ->
  react.create-factory klass

factorify-all = (obj) ->
  obj |> Obj.map ->
    factorify it

create-component = (spec) ->
  react.create-factory react.create-class spec

# Core framework namespace bundling together individual modules
module.exports =
  application: require './src/application'
  routes: require './src/routes'
  cursor: require './src/cursor'

  # move to util?
  create-component: create-component
  factorify: factorify
  factorify-all: factorify-all