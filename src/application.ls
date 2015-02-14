require! <[ react ./routes ./dom ./cursor ]>

{span} = dom

module.exports =
  # define an application instance
  create: (config) ->
    do
      # Allow definition of a different mount point.
      root: if process.env.REFLEX_ENV is 'browser' => (config.root or document.get-element-by-id 'application' or document.body) else => void

      type: react.create-class do
        display-name: 'reflex-application-root'

        render: ->
          if @props.component then
            react.create-element that.deref!, @props{state, context}
          else
            span 'Page not found'

      # The root component element
      element: -> react.create-element @type, do
        component: @state.get 'component'
        context: @state.get 'context'
        state: @state.get 'state'

      # Mount the application to the root node.
      render: -> react.render @element!, @root

      # Render the application to markup.
      to-string: -> react.render-to-string @element!

      state: null

      _routes: config.routes!

      # Initialise the application
      start: (url=routes.path!) ->
        # TODO: Abstract this route configuration into the router and expose some route mutation methods.

        # Load initial state depending on environment.
        unless process.env.REFLEX_ENV is 'browser' and state = JSON.parse @root.get-attribute 'data-reflex-app-state'
          state = config.get-initial-state!

        # App initialiser
        state = config.start state if config.start

        # Resolve the initial route and run its initialiser
        [component, context, init] = routes.resolve url, @_routes
        state = init state if init

        # Lock down state and create a cursor to it.
        @state = cursor {state, component, context}

        # Mount to DOM if we're clientside
        if process.env.REFLEX_ENV is 'browser'
          routes.start @_routes, (component, context, init) ~>
            # Update the state to reflext the new route
            @state.update (data) ->
              # Run the route initialiser if it exists
              data.state = init data.state if init
              data import {component, context}

          # Add initial on-change handler
          @state.on-change (new-cursor) ~>
            @state = new-cursor
            @render!
          
          # And finally, run initial clientside render.
          @render!

        # Otherwise return state and the rendered to string for server-side rendering
        else
          return [@state.get 'state' .deref!, @to-string!]
