# LiveScript

Reflex is a node.js and in-browser JavaScript framework, but it is itself written in [LiveScript](http://livescript.net/) - a functional style transpiled language inspired by Haskell - and our default choice of application language is LiveScript as well. Since LiveScript isn’t a high-profile language, the choice deserves an explanation.

Reflex applications are mostly written in a functional style. This is enabled by the way UI is built in React.js as a one-way functional projection of a UI model. Treating your user interface as a simple data structure and performing any state changes as changes to the data is much simpler and much more powerful than working with the UI components and ultimately the DOM directly.

## Why do I need to learn a different language?

Although all the bases are covered, JavaScript (ES 5) doesn’t make for a really great functional programming language. There are several languages transpiled into JavaScript that try and improve the syntax and semantics of ES 5 in different ways. LiveScript and it’s “standard library” prelude-ls bring very elegant and powerful functional programming with a very flexible syntax to JavaScript.

LiveScript, in its core is still JavaScript so it’s not harder to learn than, say, CoffeeScript, but it’s much more expressive. Thanks to the rich set of operators, literals and shorthands, functional concepts like currying, its flexible syntax and the prelude library it is not only clear and concise and easy to read, but also doubles as a very good replacement for JSX. That allows simple data processing to be done inline in the rendering code, which means you don’t need to prepare chunks of UI up front, resulting in a much smoother flow of code.

All these advantages together add up to a massive overall reduction and simplification of code, increase in readability and ease of maintenance resulting in a productivity boost that just cannot be ignored. Compared to similarly powerful languages, like Haskell or lisps (e.g. clojure), the learning curve isn’t nearly as steep (it just keeps on going).

[example refactoring using prelude to drive the point home]

## LiveScript as a template language

An especially interesting benefit of using LiveScript is the option not to use JSX in your components. The initial reason is simplicity and aesthetics. JSX just feels a little strange. The SGML syntax is not a particularly pleasant one to write or read.

LiveScript just makes the fact that React doesn’t need a template language obvious. Semantically, a component tag is really just a function call that optionally takes an object with props and a list of children or multiple individual child components.

To achieve this functional declarative style, Reflex uses a think wrapper around `React.DOM` and React components, that creates the element factory functions. The reason we need those is the new React API introduced in version 0.12, where defining a component doesn’t automatically create a factory function that lets you directly render that component by calling it.

Reflex’s goal is to make the UI as functional and declarative as possible. While `reflex.dom` was created out of necessity, it lets us support a few convenient API formats React itself doesn’t, like for example the ability to create elements without explicit (often empty) props

```
image = reflex.dom require ‘./image’
dom = reflex.dom

render: ->
  dom.div do
    class-name: ‘hero’ if @state.hero

    image image-key: ‘logo’, size: ‘m’
    dom.ul do
      dom.li “item”
      dom.li “another”
      dom.li “third
```

As you can see, it’s very convenient to have the full power of LiveScript in the context of writing markup. This seems like it’s breaking the separation of concerns, but really, it is the same idea as JSX, except you can do more things inline while describing the markup. Changes to add interactivity, for example, are local and very clear. The combination of React and LiveScript gets even more powerful when we introduce prelude-ls into the mix.

## Prelude LS in render

On the high level, your markup is just a functional projection of your props and state. It is a prime candidate for pure functional projection and LiveScript’s Prelude library is an excellent tool for this purpose.

Let’s say you want to render a list of item names filtered based on the item’s price and ordered by date. With JSX you’d have to prepare the list separately and “interpolate” it into the `ul` container. With LiveScript and prelude, you can map the items to components directly.

```
render ->
  dom.ul do
    items
    |> filter (.price < 100)
    |> sort (.date)
    |> map ->
      dom.li it.name
```

The pipe operator is very convenient for building streams of processing in your components. In the same way you can make decisions and generating loops or call any helper functions of your own. The result is a very natural flow of thoughts mapping your application’s state to markup.

## Why not ES 6 & JSX?

A lot of the improvements brought by LiveScript are also present in ES 6, although not nearly all of them. On the other hand, ES 6 is the future standard, which would enable us to run Reflex applications natively in the browser without the need for transpiling.

However, all browsers you need to presently support in practice will not get full native support for ES 6 for years to come; you will still need to use transpilation from ES 6 to ES 5, therefore it’s on par with LiveScript in that respect and LiveScript is still (in our opinion) a more powerful language.

That said, Reflex doesn’t stop you from writing your application in ES 6 or even ES 5 if you wish, everything will still work just fine. Our primary choice of a langue is, and for the foreseeable future will be, LiveScript.
