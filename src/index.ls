# Everyone shares a single instance of react
global.React = require 'react/addons'

require! <[ path ]>
require! './dom'

create-component = (spec) ->
  dom React.create-class spec

# Core framework namespace bundling together individual modules
module.exports =
  application: require './application'
  routes: require './routes'
  cursor: require './cursor'
  dom: dom
  DOM: dom

  # move to util?
  create-component: create-component
