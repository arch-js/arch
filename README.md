reflex
======

Web application framework for React.

## About

Reflex is a single page web application framework using React as its
UI layer. Reflex takes a functional style approach with central immutable state
architecture inspired by [Om](https://github.com/omcljs/om).

Reflex applications are written in [LiveScript](http://livescript.net)
by default (read more about [the reasoning](docs/07-livescript.md)
behind the decision), they are fully isomorphic out of the box and
Reflex comes with it's own Node.js based server, Webpack bundler
and a CLI to help you get started.

## Get Started

Start by installing the Reflex CLI

```
$ npm install -g reflex-cli
```

Then create a directory for your new application and go inside

```
$ mkdir my-app && cd my-app
```

You can then generate a new app by running

```
reflex init
```

and following the steps. When done start the application by running

```
reflex serve
```

your application is now running on <http://localhost:3000>.

## Documentation

Reflex doesn't have a website yet, but you can [read the
documentation](docs/) (which is mostly complete)
