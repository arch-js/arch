# Arch tutorial

As an introduction to Arch, we’ll build a simple application showing a list of items. We pick a listing because it’s a very common use case and the simplest example that demonstrates all the major concepts behind Arch.

## Create an Arch application

The easiest way to start is using the Arch CLI. You can install it from npm with

    npm install -g arch-cli

To create an Arch application create a new directory and run `arch-cli init` inside

    mkdir demo && cd demo
    arch-cli init

This will generate an application skeleton. You can start the application by running

    arch-cli s

and access the application on <http://localhost:3000>

## Add a route

As part of the example application, you’ll get a route to handle  the `/` URL. In most cases, you want your application’s possible general states to be linkable, i.e. serialised in and reconstructible from the URL.

You can specify routes in the `app.ls` file in the `app` directory. This file is responsible for defining your application. You create an Arch application by calling

```livescript
arch.application.create
```

and passing in an object with a handful of functions.

To define routes you specify a `routes` method, which uses a `arch.routes.define` call to declare different routes in your application. Let’s add a page listing some data.

Add a line at the end of `app/app.ls` saying

```livescript
page '/listing', listing
```

This means the ‘/listing’ URL is handled by a ‘listing’ route component.

To make this line work, you need to create the component itself. To do that create a file in the ‘app/routes’ directory, called ‘listing.ls’ with the following code:

```livescript
require! {
  './base-route': BaseRoute
  arch
}
d = arch.DOM

things =
  * "Hovercraft full of eels"
  * "Ex-parrot"
  * "Eggs, beans, bacon and spam"
  * "Flying circus"

module.exports = class Listing extends BaseRoute do
  render: ->
    d.div do
      d.h1 "A list of useful things"
      d.ul do
        things |> map ->
          d.li it
```

then change the top of `app.ls` to say

```livescript
# module dependencies
require! <[ arch ]>
global import require 'prelude-ls'

# route components
require! <[
  ./routes/welcome
  ./routes/listing
  ./routes/not-found
]>
```

so that we're able to reference the component and use `prelude-ls` implementation of `map`. You can now go to http://localhost:3000/hello and see your page rendered.

Pages (route handlers) in Arch are React components. They all share the same `props` format, specifically, they all get the
application state as their single prop, called `app-state`. To learn more about routing, read the [routing guide](08-isomorphism-routing.md).

## LiveScript as template language

The listing component code deserves a more detailed explanation. First, we don’t use JSX to define the DOM structure we’re rendering, we use pure LiveScript. Second, we use a thin wrapping layer provided by Arch to make LiveScript a very nice markup language: Each component is a simple function taking its children as arguments - either separately or in an array. Optionally, the first argument is an object with props for the component. Behind the scenes Arch uses `React.createElement` like JSX would.

The result is an almost haml/slim like template language, that is pure LiveScript. In the example route component we render a div containing a h1 and a p with some text. You can read more about the advantages of the language in the [LiveScript section](07-livescript.md)

## Adding interaction

What we built so far is, in essence, a static page. To add some interaction, we need our application to have state. Arch handles UI state in its most basic form the same way React itself does - using component’s `state`. Let’s make our list searchable.

```livescript
render: ->
  d.div do
    d.h1 "A list of useful things"
    d.form do
      d.input do
        type: 'search'
        placeholder: 'Search things'
    d.ul do
      things |> map ->
        d.li it
```

Now we need to add some state handling to make it interactive

```livescript
matches = (query, item) -->
  item.to-lower-case!.index-of(query.to-lower-case!) > -1

module.exports = class Listing extends BaseRoute
  ->
    @state = query: ''

  render: ->
    d.div do
      d.h1 "A list of useful things"
      d.form do
        d.input do
          type: 'search'
          placeholder: 'Search things'
          value: @state.query
          on-change: ~> @set-state query: it.target.value
      d.ul do
        things
        |> filter matches @state.query
        |> map ->
          d.li it
```

Notice the use of [currying](http://livescript.net/#functions-currying) in the definition of the `matches` function.

React doesn’t go much further than that. In real-world applications however, state rarely spans just a single component. The existence of the Flux architecture is good evidence of the fact.

## Centralised state instead of Flux

Arch takes a different approach to state, which is very similar to the [Om framework](https://github.com/omcljs/om) for ClojureScript. In Arch, all shared UI state is kept in a single place, the `app-state` - application state.

The application state is a “cursor” - a focused view of a part of a larger data structure that can be mutated in a controlled fashion. There is a larger discussion of the application structure in the [Arch Architecture](04-arch-architecture.md) section.

Let’s add a list of recent searches into our little demo. Since it will be another listing, we should keep our code DRY and extract the list rendering into a separate component.

```livescript
# components/list.ls

require! <[ arch ]>
d = arch.DOM

module.exports = class List extends React.Component
  render: ->
    d.ul do
      @props.items |> map ->
        d.li it
```

Then we can use it in our listing route component

```livescript
list = arch.dom require '../components/list.ls'

...

render: ->
  d.div do
    d.h1 "A list of useful things"
    d.form do
      d.input do
        type: 'search'
        placeholder: 'Search things'
        value: @state.query
        on-change: ~> @set-state query: it.target.value
    list do
      items: (things |> filter matches @state.query)
```

Actually, the filtering functionality seems very common, lets include that in the component too. Move the filtering UI from `listing.ls` to `list.ls`. The filtering logic itself is very use-case specific though, so it should be external.

This is now our listing component

```livescript
# routes/listing.ls
render: ->
  d.div do
    d.h1 "A list of useful things"
    # no more form here
    list do
      query: @state.query
      items: (things |> filter matches @state.query)
```

and the filterable list

```livescript
# components/list.ls
render: ->
  d.div do
    d.form do
      d.input do
        type: 'search'
        placeholder: 'Search things'
        value: @props.query
        on-change: ~> # now what?
    d.ul do
      @props.items |> map -> d.li it
```

This made the route component much simpler, but we now face a new problem - how do we notify whoever is interested that the user changed the query?

The solution is easy in Arch: shared state belongs to the app state. Let’s put both the query and the items there as an initial value in `app.ls`. Initially we want the query to be empty and we put our list of things in as well.

```livescript
intial-state =
  query: ''
  items:
    * "Hovercraft full of eels"
    * "Ex-parrot"
    * "Eggs, beans, bacon and spam"
    * "Flying circus"

module.exports = arch.application.create do
  get-initial-state: ->
    initial-state
```

Then we need to use that list in our listing route

```livescript
  render: ->
    query = @props.app-state.get \state.query
    items = @props.app-state.get \state.items

    d.div do
      d.h1 "A list of useful things"
      list do
        query: query
        items: (items.deref! |> filter matches query.deref!)
```

As you can see, there is a bit of ceremony going on when using the `app-state` cursor. That’s because a cursor is an explicit wrapper that acts as a reference into the application state.

Notice we first `get` the query and items from the app state. The `get` call returns a cursor backed by the same data the original was. Then we pass the query cursor down to the list component and compute the list of items it should show. To do that, we need the actual values the two new cursors are referring to, which means we need to dereference them. That’s what the `deref!` call does - it gives back the actual value behind the reference.

There is one more interesting detail in the previous code snippet - the `state.` prefix in the query and items paths. The `app-state` cursor in arch reserves the top level keys for use by the framework. At the moment, there are two keys `state` and `route`. The value for the `state` key is the user-defined application state, the value for the `route` key is the currently matched route, including the matched segment values. This way, the `app-state` contains all of the application state, including routing information.

You might be thinking “so now we’ve made a couple things much more complicated and got nothing in return”. But now, we can solve our trouble of what to do in our filterable list component.

```livescript
  render: ->
    d.div do
      d.form do
        d.input do
          type: 'search'
          placeholder: 'Search things'
          value: @props.query.deref!
          on-change: (e) ~>
            @props.query.update -> e.target.value
      d.ul do
        @props.items |> map -> d.li it
```

Everything works exactly as it did before, except our state is now central, which has countless benefits (see [Application as Data](05-application-as-data.md) for examples). Every time the state gets updated, the whole UI gets automatically re-rendered so we can see our changes (which isn’t nearly as expensive as it sounds partly through the magic of React, partly through optimisations Arch itself can do [and soon will do] thanks to the immutable data structures backing the `app-state`).

When the user types into the field, we `update` the query value to the value of the event. The `update` method actually takes a callback, instead of just taking a new value.

In Arch, the new state behind the cursor is a function of the state before the update. This lets you do in-place updates based on the previous value in a single call. (Arguably this is much less important in a single threaded application, but still has some benefits). You can learn more about how the Arch cursor works in [Cursors over Immutable Data](06-cursors-and-immutables).

Let’s finally add the list of recent queries. First we need to keep track of them.

```livescript
module.exports = class List extends React.Component
  ->
    @state = query: ''

  render: ->
    d.div do
      if @props.query
        d.form do
          on-submit: (e) ~>
            e.prevent-default!

            @props.query.update ~> @state.query
            @props.queries.update ~> [@state.query] ++ it
          d.input do
            type: 'search'
            placeholder: 'Search things'
            value: @state.query
            on-change: (e) ~>
              @set-state query: e.target.value
      d.ul do
        @props.items |> map -> d.li it
```

The list component now takes an additional prop - the list of queries to push into. Since we probably don’t want to track every single character as a new query, we’ll change the behaviour to only submit when the user presses the Enter key submitting the form. Notice the component gained some internal state again to support this behaviour. We also made a small change hiding all the filtering UI if we don’t get any query, this will be useful in a second.

The initial state needs to contain an empty list of recent queries to have somewhere to push queries in.

```livescript
intial-state =
  query: ''
  items:
    * "Hovercraft full of eels"
      * "Ex-parrot"
      * "Eggs, beans, bacon and spam"
      * "Flying circus"
  queries: []

module.exports = arch.application.create do
  get-initial-state: ->
    initial-state
```

Rendering the recent queries is as simple as adding another list component to our listing page now.

```livescript
  render: ->
    query = @props.app-state.get \state.query
    things = @props.app-state.get \state.things
    queries = @props.app-state.get \state.queries

    d.div do
      d.h1 "A list of useful things"
      list do
        query: query
        items: (things.deref! |> filter matches query.deref!)
        queries: queries

      d.h2 "Recent searches"
      list do
        items: queries.deref! |> take 5
```

Notice how our route component breaks the app state down and distributes it to its children. This is a very common pattern in Arch and the main way the applications stay modular and components stay decoupled.

You can imagine you can easily make the recent queries clickable to run them again. You just need to pass the query cursor into the second list and implement the interactivity there (at that point, it is probably becoming a different component - one that updates a state key-path with an item from a list.

## Connect to a backend API

In the previous state we grew the “state update loop” from component local to application wide. But let’s say we want to make the search actually fetch results from a backend - say Github’s user search.

First let’s think about what this means. We want to respond to the query change by issuing a request to Github API and when we get a results back (asynchronously), update the list of items. This is quite obviously not a job for a React component. The key feature of Arch's cursor that enables the behaviour is that cursors are **observable**.

Let’s create a separate module that does what we need.

```livescript
# observers/github-search.ls
require! {'isomorphic-fetch': 'fetch'}

module.exports = (query, results) ->
  query.on-change ->
    fetch "https://api.github.com/search/users?q=#{it}"
    .then (res) ->
      throw new Error(res.status-text) unless res.status in [200 til 300]
      res
    .then (res) -> res.json!
    .then (body) ->
      results.update ->
        body.items |> map (.login)
    .catch ->
```

The module exports a function, which observers the `query` cursor. Whenever it changes, the module starts an API request. Upon getting the results, it updates the `items` in the app-state, which in turn re-renders the UI.

To support this module, we need an `isomorphic-fetch` module from npm. Install it with

```
$ npm install --save isomorphic-fetch
```

We still need to hook this into the app-state. We do that in the application configuration file.

```livescript
...

# route components
require! <[
  ./routes/welcome
  ./routes/listing
  ./routes/not-found

  ./observers/github-search
]>

initial-state =
  query: ''
  items: []
  queries: []

module.exports = arch.application.create do
  get-initial-state: ->
    initial-state

  start: (app-state) ->
    query = app-state.get \state.query
    items = app-state.get \state.items

    github-search query, items

...
```

Notice the search initialisation is again independent of the structure of the app-state itself. It only requires a query cursor to observe and an items cursor to update.

Finally, we need to make a slight change to our `listing` route:

```livescript
render: ->
  query = @props.app-state.get \state.query
  items = @props.app-state.get \state.items
  queries = @props.app-state.get \state.queries

  d.div do
    d.h1 "A list of useful things"
    list do
      query: query
      items: items.deref!
      queries: queries

    d.h2 "Recent searches"
    list do
      items: queries.deref! |> take 5
```

We also no longer need the `matches` function at the top. This is coincidentally very good for decoupling the UI from the business logic - if we decide to change the search to something completely different, we just switch the search provider in `app.ls`

If you now type into the search field and hit enter, you should get a list of top 50 matching Github users. You could very easily implement a loading indicator by adding an in-progress flag, turn it on when the request is initiated and flipping it back off when it has finished.

## Conclusion

This concludes the introductory Arch tutorial. You may have noticed that Arch focuses primarily on state management. State is absolutely central (no pun intended) to Arch. Most of the advanced features of Arch and applications built on it are only possible because of the strict way application state is managed.

In this tutorial, you’ve seen how there are various scopes of state – sizes of the state loop: component local, global - shared between components, global - shared between the app and an API.

The latter case demonstrated one use-case for state observers, but you can extract various different common tasks into state observers (form validation, domain logic computations, service integrations, metrics collection, persistence…). See [Application as Data]() for a larger discussion of the concept of central state.
