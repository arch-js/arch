require! <[ page ]>

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

# Parse a URL into a context object, including extra parameters if
# necessary.
context-from-url = (url, params) ->
  [path, qs, hash] = split-url url
  query = parse-query(qs)

  canonical-path: url
  path: path
  query-string: qs
  hash: hash
  query: query
  params: ({} import query) import params

module.exports =
  define: (...configs) ->
    configs

  page: (pattern, component-class, init) ->
    # uses page.js Route to match and resolve routes

    route: new page.Route pattern
    component: component-class
    init: if 'function' is typeof init then init

  start: (configs, root-component, app-state) ->
    configs |> each (config) ->
      page.callbacks.push config.route.middleware (ctx) ->
        context = context-from-url(ctx.canonical-path, ctx.params)

        root-component.set-state component: config.component, context: context
        window.scroll-to 0, 0

        # call the route callback
        config.init(app-state, context, ->) if config.init

    # only start client-side routing if pushState is available
    page.start! if (typeof window.history.replace-state isnt 'undefined')

  resolve: (url, config) ->
    params = []
    route = config |> find -> it.route.match url, params

    return [null] unless route

    context  = context-from-url url, params
    [route.component, context, route.init]
