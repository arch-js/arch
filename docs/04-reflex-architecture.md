# Reflex architecture

Reflex strives to reduce the complexity of user facing applications as much as possible [in the same sense React does](https://speakerdeck.com/vjeux/why-does-react-scale-jsconf-2014) - reducing the time to find a cause of a problem. That means reducing the number of places where a problem you are diagnosing can be caused.

One of the biggest reasons for unexpected behaviour is state (we often say “state is your wort enemy”). State handling therefore requires extra care when designing an application architecture. A big step in reducing the state space of your application is following the methods of functional programming - a pure function, by definition, has no internal state and is referentially transparent (calling the function with the same arguments always produces the same results) - which Reflex promotes.

You cannot avoid all state though. So even when building applications in a functional style, you still need to  pay extra attention to managing your application's state.

## Flux architecture

A popular choice for a high-level React application architecture  is flux. It promotes unidirectional data flow with state kept in a set of stores and updates being distributed through the app  using observation - components subscribe for notifications of changes from the stores and update the UI accordingly. The stores themselves listen for user events on a central event bus called dispatcher, acting like a publish/subscribe mechanism for components to broadcast user events and stores and other modules to respond to them.

```
  .- > [dispatcher] => [[stores]] => [[components]] -.
  |                                                  |
  ` - - - - - - - - - (events) - - - - - - - - - - - ‘
```

### Issues with flux

Although flux is quite flexible and easy to understand, building your application in it still results in an MVC-like separation of concerns, where your application data is encapsulated in the stores requiring co-operation between them and preventing use of basic data processing functions to work with it, instead requiring you to add more and more methods on the stores, eventually leading to a large object-oriented architecture. Meanwhile a place to store general UI state (e.g. “a dialog box is open”) is either missing or put at the same level as one of the data stores.

Your stores also need to provide all synchronisation with any backend services, resulting in a fairly tight coupling of the stores (and therefore your state) to your backend API without special care.

Crucially, you need to pass the stores to your top-level react components for them to listen for changes. This means your components only work if you pass in one or more fairly complex objects with a lot of internal state, which makes it difficult to test the components and more importantly to generally reason about their logic. Reflex components are meant to be purely functional, that is, be a pure function of their props (and the internal state). This means they should only receive plain data (or something very close to it) in `props`.

## Centralised state

Taking inspiration from the Om framework for ClojureScript, Reflex aims to resolve the above issues using a centralised application state. The application state is a single, tree-like data structure, modelling the state of your user interface as data. That has several advantages: you can reconstruct your application into any stat just by loading the right application state, you can use state for bug reporting, you can record a history of the state to implement undo functionality, persist the state in different places and easily restore the UI state, etc…

On the other hand, having one global state breaks component isolation - the components are no longer independent of the global structure of your app state. To get the isolation back, you need to make the global state “feel” like local state. Specifically, this means allowing components to use the state data freely without affecting other components in an unexpected ways, yet still allowing them to explicitly update the state.

Reflex uses the same technology as Om to achieve this - cursors over immutable data structures. Reflex app state cursor is designed such that you don’t need to work with immutable data structures unless you explicitly ask for them.

Cursors are simple wrappers around a complex data structure that can focus on a part of it, hide the rest of the structure from the consumer, but still propagate updates back to the full structure. You can think of a cursor as a read-only reference to a sub-tree of the state. In addition, you get a mechanism of mutating the reference in a controlled way that applies your changes to the backing central data structure. For a detailed discussion of how the cursor works, refer to [Cursors over Immutable Data](06-cursors-and-immutables.md).

## Working with cursors

As a consuming component you receive the app state or its sub-cursor in a prop. You can either focus it some more, using a `.get` method (which accepts a dot separated key path) and pass it down to child components you’re rendering, or dereference it to get the data and use it for computation or display using `.deref`. Cursors to arrays behave like arrays (in fact, they are arrays of cursors to the items), you can iterate through them, map them, etc. Finally to update the state and re-render the relevant portions of the UI, you can `.update` a cursor, which accepts an update callback that receives the previous value and returns the new one, for example:

```
increment-age: (age-cursor) ->
  age-cursor.update -> it + 1
```

The main difference between Reflex and Om cursor implementation (and most others) is that Reflex cursors are observable on any key path. Observers are notified of any changes happening to the key path they are watching and all its children.

This is immensely important for the application architecture - the application state acts as a central column that modules of your application are attached to. On one side, there is a tree of components reading the application state data and displaying it accordingly, on the other side there are various modules observing the state changes, performing computations and updating the state. Reflex itself is watching the root application state cursor and re-renders the relevant React components.

The running application is a dialog of the UI and the state observers taking turns updating the state. A user event in the UI causes either a component state update or an application state update. In the latter case one (or more) observers pick up the change and perform what they are built to do. When their job is done, they put the results on the app state, which causes the UI to re-render.

This architecture achieves a very loose coupling between the front-end and the back-end part of the application (“vertical coupling”) as well as between the components of the UI across the hierarchy (“horizontal coupling”). Each component only needs to understand what its layer of the app state looks like and potentially some details of the layers above and below. At the same time it allows things like multiple back-end adapters racing to perform the same task using different ways, or easy back-end swapping even at run-time. Even tasks as simple as form validation can be extracted from the components and become state observers. The UI components themselves stay focused on interfacing with the user and performing simple state changes.
