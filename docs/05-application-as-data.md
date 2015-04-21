# Application as Data

The main change in the approach React takes to building user interfaces is how it
handles the data your UI is rendering. You start building your interface from a
static markup. Then you decide which aspects of the content you need to control
from outside of the component (`props`) and finally you add interaction by letting
some of the data change (by abstracting it into the `state`). Your user interface
thus becomes a projection of a data structure composed of the `props` and the
`state`. Your UI is a function of the `props` and `state`.

Arch takes this approach and scales it beyond a single component, while making
it look, if you squint a little, as if nothing changed for the components themselves.
When you need to share some data between two components, you can promote it onto
the shared central app-state and pass a cursor to both components in `props`.
Components are also allowed to modify the data they’ve got in props and Arch
propagates the updates to the rest of the application.

In Arch, your whole UI is a functional projection of the app-state (plus the
current URL). Think of that again, your _entire_ user interface state is described
by a single data structure. For the components, though, everything still feels
like simple, local data.

When taking this approach, you'll find the central app-state becomes a simple data
model of your *user interface* (not your application data!). Instead of starting
from the markup, you can start from a minimal description of your user interface
as a data structure and how the different modes will be represented. This model
becomes the foundation of your entire application (and looking at it should
reveal a lot of the intent you had building it and its general function).

For example, here is what a blog app-state could look like when on the listing
page:

```livescript
articles:
  loading: false
  total: 8
  items:
    * title: My first blog
      published: Date
      abstract: This is the first blog on my website
      comments: 1
    * title: Loving Arch so far
      published: Date
      abstract: Building applications in Arch is so easy!
      comments: 6
    * ...
article:
  loading: false
  content: null
tags:
  javascript: 5
  arch: 3
  react: 7
  ...
```

and so on. Looking at the data structure makes it quite clear what the application
is all about. A chat application would look very different from a news site or a
customer database. It also makes it easy to see what the application is doing
at this point in time.

## Benefits of the central state

This makes a lot of things very simple. Reproducing any problem, for instance,
is a matter of rendering the application with the problematic app-state. By
being, in essence, a simple (albeit fairly big) data structure, you don’t have
any code dependencies between your domain model and your UI code - only data
structure dependencies.

The other important aspect of the Arch app-state is that it is backed by an
immutable data structure, ensuring that whenever you `.deref!` a cursor, the data
you get back is yours and yours only. It can never change in your hands. No need
to ever again try to track down some innocent looking write to a function argument
causing a bug at the other end of your application.

Finally, making your entire UI state a single data structure, you can do many
things you cannot do with a state spread across multiple places encapsulated
inside object instances.

You can, for example, record every state of the app-state over time (which is
fairly cheap again thanks to being backed by an immutable data structure which employs structural sharing) and
get a very crude undo functionality almost for free. It is entirely possible to
record the full user session this way making reproduction of issues dead simple -
you can just replay the app-state and watch the application get into an
unexpected state. You can also very easily persist your application state to
restore it later or even send it somewhere.

## Simple data beats domain model objects every time

All of the above is made possible by using plain data model, rather than objects
with methods, to back your user interface. By making the state observable at the
same time, you achieve complete decoupling of your UI from your business logic
through the state. As long as you keep the produced and expected data structures
the same, you can swap state observers or even run multiple ones at the same time.

Instead of manipulating the DOM in response to user actions and other events, you
can manipulate a simple, concise data structure describing your application’s state
which is much simpler, easier to reason about and side-effect free. You also use the state to mediate
communication between parts of your application in a simple observable fashion.

Finally, you keep all of the (interesting) state in your application in a single place,
making all of your other code state-less, i.e. purely functional. The simplification brought
by this separation cannot be overstated. Having all state on one side and all logic
state-less is easier to keep track of, reason about, test manually and automatically, persist and restore, even construct your application's state artificially.

## Complete state, not complete data

One thing to note is that having your entire application state in the single data structure
doesn't mean having all of your application data (i.e. the entire possible state space) in it at the same
time. Your app-state only needs to contain as much data at the time as you plan to present
to the user.

Arguably the limits of how much a human can take in from the screen are much lower
than the technical limits to the amount of data the JavaScript runtime and your
application as a whole can handle at any one time. Much of the focus on handling data
in larger applications will be in getting the right data into the app-state at the right
time and recent technologies like Facebook's Relay and Graph API should help with that.
