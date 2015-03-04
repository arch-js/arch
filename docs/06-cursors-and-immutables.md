# Cursors over Immutable Data

In this section we’ll discuss the details and reasons for using cursors over immutable data structures as the storage mechanism for state in Reflex rather than mutable data.

## The value of values

> The title of this section is a blatant rip-off of a [talk by Rich Hickey](https://www.youtube.com/watch?v=-6BsiVyC1kM) which you should absolutely watch. Right now.

There is one important distinction we (as developers) fail to make most of the time: the distinction between a **value** and an **identity**. The reason for this distinction to be necessary is the existence of time. Without time and changes happening over time, we would only have values.

As programmers, we work with variables, which change over time. Variables of a simple type, like numbers, take values that are simple and immutable. The number 5 is a number 5 in any context and it never changes. A numeric variable can, on the other hand, take on any other value. The variable (i.e. the name) is important for us to keep track of a quantity, e.g. person’s age.

This becomes important when you share the person’s age with someone, e.g. pass it into a function, send it to an API, etc. For numbers, you share the value, e.g. 30. That on itself is enough for someone to perform calculations, or do anything they want. Crucially, them working with the value has **no effect** on the person’s age. The only way to change a person’s age is to update the identity to a new number. (Notice the update doesn’t affect anyone performing calculation with the original number!).

An identity is therefore a series of values over time. At least that’s the case for simple data types like numbers or strings. The situation changes when we get to composite data structures, like arrays (vectors) and objects (maps). These are, for all intents and purposes, values, but, in most programming languages, they are mutable.

When you share a list of user’s phone numbers with someone and they update the list (say, remove a number from it), *absurdly* the original user’s phone numbers change for everyone holding the same list. This makes it really difficult to keep track of where changes are made and what effects they might have. What we need is for arrays and objects to be simple values as well, i.e. to be immutable.

## Immutable data structures

Immutability is a guarantee that lets you freely share values with everyone, knowing they can never change in your hands. Obviously, it’s not practical to only work with constants. We need to change the contents of the data structures. The simple solution is for mutations to return an independent new immutable **value**, the same way arithmetics with numbers do. Incrementing a person’s age creates a new person with the age changed. To update the original person, you just need to assign that new value to the original reference, i.e. update the identity.

You are now probably thinking: “Does that mean we’re duplicating the person object every time we change anything? That cannot possibly perform well”. Of course we are not cloning the whole data structure any time we make a change. The key to making changes to immutable data structure efficient is structural sharing.

### Structural sharing

Structural sharing is an optimisation shared by all implementations of immutable data structures. It’s not by any means a new idea. Think of a simple linked list.

[image]

When you push an item into a list, you add a node. Anyone holding a reference to the original list still sees it intact. When you pop an item from that list, you get a reference for the next item. Anyone holding a reference to the original list can still see it, as long as you don’t deallocate the removed item. Adding and removing items into the list eventually creates an item graph in memory that keeps all the various states in the history of the list intact, as long as someone needs the particular item. When all the references to a certain head of the list are lost, it gets garbage collected

[image after]

This idea scales very well to tree data structures. In fact, you are probably using one such data structure all the time: a git repository. A commit in a git repository is an immutable tree of file objects. Creating a new commit updates the changed files, all their parent directories all the way to the root and creates a new commit object pointing to the top level directory (to access the content) and to the previous commit (to keep the history). A commit is a **value** describing a state of a file tree.

In git you usually access commits through branches, which are just referencing commit objects that are the most recent state of a given branch. As you add commits over **time**, the reference gets updated, serving as an **identity** for you to reason about your code branches.

### Maps and Vectors

We mentioned above that the two basic composite data structures we need are objects - key-value maps - and vectors - indexed arrays of values. These can both be implemented as a tree data structure called Trie.

Tries work by storing values in a tree branched by parts of the keys. Say you want to store something at position 3579 of a vector. One way of setting up a trie for it would be to take a single digit at a time at each level of the tree. In the root node, you’d look at position 3 of 10. You’d either find a value, or another trie node. In that one, you’d look at position 5 of 10 (3 was already used) and so on.

For a vector, this is enough. [TODO explain actual vector impl.]

For a Map, you need to store key-value pairs, where keys can be anything. The tool to help you overcome the limitation is hashing - a one way function that gives you a unique number for each value (like md5 or sha1). The resulting data structure is called hash array mapped trie. To look up an item, you compute a hash of the key and then divide it into 5-bit pieces (for a 32-way branching, which is efficient). Then you follow the same procedure described above for key 3579 (except that for each step, you’ll have 32 options, not 10).

### Mutation

Mutation in a trie simply requires finding a node that should store the value, duplicating it, performing the required update and then duplicating all it’s parent nodes and updating the references to the child. This process is called path copying.

[picture with sharing]

Because of the high branching factor, this process is actually really efficient, requiring only a few steps to find or update a value (up to 6 for a full trie of over a *billion* items).

When the reference to the original root is lost, the changed nodes get garbage collected.

[picture with the old structure gone]

## Bringing the state back

In practice, we need to keep a state value in a mutable reference. The advantage of using an immutable state is that the updates are very controlled and can only happen by replacing the entire thing. Combined with centralised state in Reflex applications having immutable state would unfortunately mean anyone working with the state needs to understand the full structure of it to perform updates. That is obviously not practical.

### Cursors

The solution is simple - we need mutable references to a particular item - or “sub-tree” - in the state data structure, which we can pass to a component as if it was standalone. You can imagine it as zooming in onto the part interesting to the component.

The same thing must work the other way round as well: when the zoomed-in structure is mutated, the updates need to propagate back to the original data structure. When you update a cursor, the update gets applied to the right subtree of the full data structure and the backing reference gets updated.

The cursor is a simple data structure holding a reference to the root cursor (the one holding the entire backing data structure) and a key-path to which it is focused. That allows the cursor to  easily derive sub-cursors by appending keys to the path they hold. Cursors themselves are immutable (although in Reflex that behaviour is not forced): when you get a sub-cursor, you get a new cursor back.

To update a cursor, you supply a function that takes the current data pointed to by the cursor and produces the new data. The cursor takes the new data and produces a new root data structure where the item it is pointing to is replaced by the data returned by your function. Then it swaps the backing data structure in the root cursor.

## Effectively local state

The use of cursors in Reflex effectively brings working with shared state back to the level of individual components - a component only needs to know what data it expects in props and which of them are mutable, i.e. cursors. During its lifetime it either mutates the cursors it received or zooms in to distribute them into child components.

This means that no component ever needs to know more than its local part of the state tree. Specifically speaking it needs to know what data it requires and how to get data required by its child components from it.

[image: state tree and component tree]

It’s natural for the state tree to follow roughly the same hierarchy as the UI itself, but usually a coarser one - not every node in the component tree is necessarily a node in the state tree.

Rendering UI is not the only thing you ever want to do with your application state of course. The natural question is where should other computation happen - you need to pick a component responsible for performing each task. But actually, a component is the wrong place to perform these tasks in the first place. They need to be performed independently.

## Observability

Reflex cursors allow anyone to plug in any data processing necessary by registering for state updates on any cursor. When you do, any time the item in the data structure pointed to by the cursor changes, all observers registered on it and any of its parents all the way back to the root are notified.

Reflex itself observers the root cursor of the app state and re-renders the root UI component whenever it changes. This implicit rendering means you don’t need to trigger, distribute and handle user events in your application manually (e.g. with a Flux style dispatcher). A user action *always* results in a state change which should either render the UI again or trigger some processing through observation.

### Observer “ping pong”

A typical pattern for state observers is to have a kind of dialog with the UI components. User actions are handled by the component, which in turn change the app state. The change is registered by one or more observers (e.g. a search backend or a persistence provider) and the result of their work again updates the app state. Finally, that update triggers a redraw of the UI, showing the results to the user.

A nice benefit of this approach is that the stages of the processing are explicit and you can show the progress of a long running operation to the user (e.g. have a ‘loading’ flag used to trigger a fetch from a backend and display or hide a loading indicator at the same time).

Reflex forces you to make even transient states explicit, which is usually beneficial to your application design.

## Cursor API

The cursors have a very simple API. The fundamental operations with a cursor are a creation, focusing, dereferencing, updating and observing.

### cursor

### get

### deref

### raw

### update

### on-change
