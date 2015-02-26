# Everyone shares a single instance of react
global.React = require 'react/addons'

# FIXME require server-rendering only on the server
require! <[ path ./dom ./server-rendering ]>

create-component = (spec) ->
  dom React.create-class spec

# Core framework namespace bundling together individual modules
module.exports =
  application: require './application'
  routes: require './routes'
  cursor: require './cursor'
  dom: dom
  DOM: dom

  # TODO support client-side redirect as well
  redirect: server-rendering.redirect

  # move to util? or remove entirely
  create-component: create-component
