# Isomorphism and Routing

An important aspect of building a client-side single-page application is URL handling, i.e. displaying the right content or user interface for the right URL, so that you can use links in your application.

Traditionally, single-page applications handle URLs in the browser using `pushState` DOM API or the URL fragment (the part of URL after #). Coupled with click handlers on local links, this prevents any actual page loads and all content changes happen in the browser, i.e. you render everything using JavaScript.  

On the other hand, this means the page delivered to the browser on initial request is the same - an empty page with a JavaScript bundle which, when started, reads the URL and renders the page. This is the approach taken by Backbone, Angular, Ember.js and other front-end frameworks.

This approach has a big problem - a web client which doesn’t run JavaScript (like most bots and generally any other web clients that are not a modern web browser). This means the content isn’t  accessible by search engines, when you post things to social networks, their crawlers cannot derive extended metadata (like a nice picture to accompany your post), etc.

In this sense, single-page applications break the web. In exchange, you get a great user experience and speed, because you don’t wait for a full page load every time like you would with a classic, server rendered web application (built with PHP or Ruby on Rails for instance). In reality, you need to support both cases.

## Isomorphic applications

Normally, supporting client-side and server-side rendering means having separate code paths for each. This means a duplication of effort and usually a mediocre content shown to users without JavaScript.

Recently a different approach emerged, usually called isomorphic web applications. These are applications that can render the exact same content for the same URL on the server or in the browser. Notable examples are the Meteor framework and Airbnb’s Rendr. An implied feature of this approach is sharing the rendering code between the client and the server.

The net result of building an isomorphic application is the ability to switch from JavaScript routing and rendering to full page loads at any point in the user’s journey. This is also where the term isomorphic comes from - although the operations carried out by the server and the browsers to navigate between pages are different, the results are the same. It doesn’t matter if you transition between pages A and B purely in the browser and then perform a full page load of page C or make a full network request from A to B and then transition to C with javascript in the browser.

There are numerous practical benefits: Search engines get the same content your users do, your page renders faster, because the content eventually rendered by JavaScript is present before the JavaScript is even loaded and finally, you can just turn the client-side rendering off for devices with slow JavaScript runtimes (e.g. older Android phones).

## Isomorphic by default, client first

Reflex is isomorphic out of the box. It comes with it’s own node.js based server, which handles the server side of things and you never need to worry about it. Write your application as if it was client-side only and Reflex will handle the rest. We call this approach “client first” development.

In practice, this means you define your URL mappings (“routes”) just once and they will work on both sides. Each URL (route) is handled by a route component - a react component describing your page on the top level. All route components share a `props` format: they receive  `app-state` - your application state cursor and `context` - the parsed route and all data derived from it (routes can have dynamic segments, e.g. `/users/:name`).

Reflex also lets you perform some operations whenever the application transitions to a given route (e.g. start fetching some data form an API). Let’s look at an example route definition in `app.ls`:

```livescript
page = reflex.routes.page
routes.define do
  page '/', home-page
  page '/archives/:year/:month/:day', blog-archive, (state) ->
		return unless empty (state.get \articles .deref!)
		state.get \loading-articles .update -> true

	page '/blog/:slug', blog-article, (state, context) ->
		slug = context.params.slug
		article = state.get "article"
		return if article.get "slug" .deref! is slug

		article.update -> slug: slug, loading: true

	page '*', static-page
```

There’s a lot going on here, so let’s look at it route by route. First, we define a home page route, matching a `/` URL. That route is represented by the `home-page` component. Whenever we respond to `/`, the `home-page` component will get rendered with the current `app-state`.

Next we define a route with some dynamic segments for a blog archive page. The `blog-archive` component will get the actual values for parameters `year`, `month` and `day` in the `context` prop. This route also has an initialiser function, which makes sure the article list is available. If it isn’t, it sets a `loading-articles` flag to `true`, which gets picked up by a state observer (which isn’t shown for the sake of simplicity).

In response the observer will fetch the list of articles from the API and when done, update the state, putting the list onto the `articles` path, also setting the `loading-article` flag back to false. The `loading-article` flag can be used by the component to render a loading indicator. See the [Reflex architecture](04-reflex-architecture.md) section for more details about the state observer pattern.

The third route is very similar to the second one, except it uses the URL context directly in it’s initialiser, fetching the currently shown article.

The routes we defined above work exactly the same way when accessed as the first page load, or in the browser. On the server, Reflex will look up the component and render it. In the browser, it will handle a link click preventing a page load and swapping the route component instead.

The above are the simple cases of isomorphic rendering. As always, there are also annoying edge cases.

## Outer page layout

One issue with using React for isomorphic rendering is with managing the “outer” html - the `head` element, everything in it, and the attributes on `html` element itself. We call this the outer layout [pending better name].

Reflex lets the route components define their own outer layout with the assumption that its content (with the exception of page title) will only change with each full page render. The assumption is all the meta tags and other content specific to each page is there for “compliance with the web” and therefore only matters when rendering server-side. There are major limitations trying to render full html with React, which is another reason Reflex doesn’t attempt to do that.

The route component needs to define a `get-layout-template` method, which returns a layout template function of a single argument - a context object. The context object has two keys: `title` and `body`. Title is the current page title and body is the Reflex application snippet containing the application DOM element (including rendered route), script bundle and initialisation call. The layout template function returns a full HTML of the page.

There is one more method a route component needs to define - the `get-title` method, which returns a string - the current page title. Being an instance method of the route component, it can use both its props and state to construct the title. This method is called once for server-side rendering and then again each time the route changes client-side, which lets Reflex update the page title as the user navigates between pages of your application.

## Initial state

With server-side rendering, your applications gets initialised twice - once on the server, once on the client. As the process presumably results in an app-state update, Reflex lets you easily skip the initialisation done server-side on the client by making the resulting server-side state the initial client-side state, i.e. anything the initialisation does on the server will automatically be available once the app starts on the client. The initial app state gets sent JSON serialised in a data attribute on the root DOM element of your application.

Because of this behaviour you shouldn’t assume a known initial state in your application initialisation process (and route initialisers) as it may be the second time they ran and the resulting data may already be on the app state.

## Asynchronous initial state

Sometimes it isn’t enough to just render the initial state of a page server-side. A typical example would be content loaded from an API that needs to get rendered even if JavaScript isn’t available on the client. However, the initial API request is an asynchronous operation and you need to wait for it to finish before rendering.

Reflex solves this problem by supporting asynchronous state observers. Any `on-change` handler on the app-state cursor may return a promise which it will resolve once the asynchronous operation it’s performing finishes. If you do that, server-side, Reflex will wait for those handlers to finish before it renders the page.

In practice, it means you can kick-off your API request by updating the app-state (which is a synchronous operation) and handling the change, returning a promise for the finished API request. All the promises returned by the various state observers will get collected and when they all resolve, Reflex will render. Once your API request is done, you can update the app-state again with the results. You can even chain asynchronous change handlers this way and Reflex will wait for everything to settle before rendering.

On the client, this isn’t necessary, because the application will keep running after the initial render and it is a better experience to render the page partially and show a loading indicator to the user while finishing the content loading. Using asynchronous observers you can precisely define which content is necessary for the initial page render and which isn’t. You effectively get a knob you can turn to decide what portion of the page load should happen on the server and what on the client.

You obviously get the benefit of doing the API fetch just once on the server, because Reflex will ship the resulting app-state within the page and load it as initial state, which lets you easily skip the request in the browser if data is already present.

## Form processing

The major issue with isomorphic applications is that of form processing. You can easily reuse React rendering code in the browser and on the server with React’s `renderToString`, but it is not as easy with submitting forms.

Reflex offers a solution for fully isomorphic form processing. It is probably no surprise that the
approach is client-first. You build your form as if your application was only meant to work in the
browser and as long as you conform to a small set of conventions, your form will also correctly
submit via a POST request.

To conform to the conventions, you need to do the following in your form component:

* set method to POST and action to the same URL that renders the form (e.g. `/articles/create`)
* use `on-change` handlers on your form inputs to keep current input values in sync with your state
* use `on-submit` handler to update your application state with the result of the form processing - i.e. either a new record created or the validation errors.  
* The form submission/validation *must* result in an app-state update.

Other than that, your forms can work however you want them to. On the server, the `on-change` handlers will be used to fill in the fields, the `on-submit` will get called and when the app-state settles, Reflex will re-render the page with the new state. You may also redirect to a different page using a `Reflex.redirect` call.

> Note that this functionality is still in its early stages and considered experimental. Specifically, the way
Reflex simulates change and submit events on the server is very limited at the moment and does not follow the DOM API closely.

## Routing API

TODO
