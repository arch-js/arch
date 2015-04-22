routes = require '../src/routes'

describe "routes" (_) ->
  describe "definition" (_) ->
    it "handles a single simple route" ->
      rts = routes.define do
        routes.page "/", "component"

      route = routes.resolve rts, "/"
      expect route.0 .to-be "component"

    it "handles multiple simple routes" ->
      rts = routes.define do
        routes.page "/", "component"
        routes.page "/blah", "component2"

      route = routes.resolve rts, "/"
      expect route.0 .to-be "component"

      route = routes.resolve rts, "/blah"
      expect route.0 .to-be "component2"

    it "handles a route with a matched segment" ->
      params = []
      rts = routes.define do
        routes.page "/users/:username", "user"

      expect routes.resolve rts, "/users/" .to-equal [null]

      route = routes.resolve "/users/her-majesty-the-queen", rts
      expect route.0 .to-be "user"
      expect route.1.params .to-equal username: 'her-majesty-the-queen'

      route = routes.resolve rts, "/users/bob"
      expect route.0 .to-be "user"
      expect route.1.params .to-equal username: 'bob'

    it "handles a route with a glob" ->
      params = []
      rts = routes.define do
        routes.page "*", "404"

      route = routes.resolve rts, "/pages/amazing-article/1"
      expect route.0 .to-be "404"
      expect route.1.path .to-be "/pages/amazing-article/1"

    it "puts query string and hash into the context" ->
      params = []
      rts = routes.define do
        routes.page "/users/:username", "user"

      route = routes.resolve rts, '/users/bob?tab=profile#education'
      expect route.0 .to-be "user"
      expect route.1.params .to-equal username: 'bob', tab: 'profile'
      expect route.1.query .to-equal tab: 'profile'
      expect route.1.hash .to-be 'education'
