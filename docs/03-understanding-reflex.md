# Understanding Arch

Arch is a web application framework for building the user interface layer of multi-layered web applications. The UI layer of Arch is provided by React JS and Arch supplies the rest of the architecture: routing, global state management and support for isomorphic rendering [rendering?], as well as some convenience helpers for the way we think React applications should be built.

Arch comes with a CLI to generate and run the applications conveniently, but also supports running a server without the CLI as a stand-alone server or part of a larger node.js application.

> The latter option, as is often the case with Arch, is provided for exceptional cases where such architecture is needed, but generally it’s not recommended.

## Client-first and Isomorphic

Arch applications are meant to be backed by a backend layer in the form of an API server(s) or service(s) and Arch therefore doesn’t have any provisions for server-side only code. You build an Arch application as a javascript single-page application.

Traditional single-page applications have several drawbacks (you can go as far as saying they “break the web” [link]), which Arch addresses by providing isomorphic routing and rendering out of the box without a need for any server specific code. You treat your application as if it’s client-side only and Arch does the work to make it a good web application. We call this approach client-first.

See the isomorphism section for additional details and conventions to allow full isomorphism.

## Opinionated, but flexible and modular

* made choices and created abstractions
* always provided an escape hatch
* possible to use individual parts of Arch

## Functional style and explicit state handling

* Functional programming is simpler and easier to test
* State is hard and it’s harder to introduce in functional style
* Explicit central state has countless advantages

## Promoting separation of concerns

* components are (almost) pure functions: state -> UI
* state observers and how they allow modularity
