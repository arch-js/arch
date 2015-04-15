require! 'page'

{split-at, drop, split, map, pairs-to-obj, each, find} = require 'prelude-ls'

# Split URL into path, query string and hash
# => [path, query, hash]
split-url = (url) ->
  qs-index = url.index-of '?'
  return [url, null, null] if qs-index < 0

  [path, rest] = split-at qs-index, url
  rest = drop 1, rest

  h-index = rest.index-of '#'
  return [path, rest, null] if h-index < 0

  [qs, hash] = split-at h-index, rest
  [path, qs, (drop 1, hash)]

# Parse query string into an object
#
#   parse-query("foo=bar&moo=oink")
#   # => {foo: "bar", moo: "oink"}
parse-query = (query) ->
  return {} unless query

  query
  |> split "&"
  |> map ->
    [key, value] = it |> split "="
    [key, decodeURIComponent(value)]
  |> pairs-to-obj

component-id = (route) ->
  route.pattern

# Parse a URL into a context object, including extra parameters if
# necessary.
context-from-url = (url, route, params) ->
  [path, qs, hash] = split-url url
  query = parse-query(qs)

  component-id: component-id(route) # for now, probably something else later
  canonical-path: url
  path: path
  query-string: qs
  hash: hash
  query: query
  params: ({} import query) import params

module.exports =
  # Public: is the client side routing running
  running: false

  # Public: define a route set
  #
  # returns an opaque structure with route definitions
  define: (...configs) ->
    routes: configs
    components: (configs |> map (-> [component-id(it), it.component]) |> pairs-to-obj)

  # Public: declare a route matching a pattern to a component class
  page: (pattern, component-class) ->
    pattern: pattern # used as a route key
    route: new page.Route pattern  # use page.js Route to match and resolve routes
    component: component-class

  # Public: explicitly change the current route
  navigate: (path) ->
    page.show path

  # Public: start the routing
  start: (route-set, app-state) ->
    route-set.routes |> each (route) ->
      page.callbacks.push route.route.middleware (ctx) ->
        context = context-from-url(ctx.canonical-path, route, ctx.params)

        # Put the new route on the app state
        app-state.get \route .update -> context

    # only start client-side routing if pushState is available
    page.start! if (typeof window.history.replace-state isnt 'undefined')
    @running = true

  # Public: Resolve a given url to a context based on a route set
  resolve: (route-set, url) ->
    params = []
    route = route-set.routes |> find -> it.route.match url, params
    return null unless route

    context-from-url url, route, params

  # Public: lookup a component for a route in the route set
  get-component: (route-set, component-id) -->
    # this is a function on routes for forward compatibility
    route-set.components[component-id]
