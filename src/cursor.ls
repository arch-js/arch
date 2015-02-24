Immutable = require 'immutable'
{map, take, reverse, each, join, split, is-type, empty, obj-to-pairs, first} = require 'prelude-ls'

# wraps array in a cursor
array-cursor = (root, data, len, path) ->
  array = [0 til len] |> map ->
    new Cursor(root, null, path ++ [it])

  array._path = path
  array._root = root or this
  array._data = if data then Immutable.fromJS(data) else null
  array._listeners = {}

  # Support all the cursor API
  array{get, deref, raw, update, on-change, eq} = Cursor.prototype

  return array

# new cursor from non-array data
object-cursor = (root, data, path) ->
  new Cursor root, data, path

# Notify changes on all a cursor's parent paths.
notify-changes = (from, to) ->
  # Diffnotify
  from._root._listeners
  |> obj-to-pairs
  |> each ([path, listeners]) ->
    if n = (if path is "" then to._root else to.get path)
      if !n.eq (if path is "" then from._root else from._root.get path)
        listeners |> each (-> it n)

# Perform an update on cursor a, returning cursor b with the same listeners and update queue attached.
perform-update = (cursor, update, notify=true) ->
  old-val = cursor.raw!

  new-val = update cursor.deref!
  new-val = Immutable.fromJS(new-val) if is-type 'Array', new-val or is-type 'Object', new-val

  return cursor if old-val is new-val or Immutable.is(old-val, new-val)

  if empty cursor._path
    new-root = make-cursor new-val
    node = new-root
  else
    new-root = make-cursor cursor._root._data.set-in cursor._path, new-val
    node = new-root.get (join '.', cursor._path)

  if notify
    notify-changes cursor, new-root
    new-root._listeners = cursor._root._listeners

  new-root._updates = cursor._root._updates

  node

# Cursor initialiser
Cursor = (root, data, path) ->
  @_path = path
  @_root = root or this
  @_data = if data then Immutable.fromJS(data) else null
  @_listeners = {}
  @_updates = []

  this

# Get a sub-cursor or 'view' of the current cursor
Cursor.prototype.get = (path) ->
  path = @_path ++ (split '.', path)
  val = @_root._data.get-in path

  return null unless val

  # if the resulting object is a list, return array-cursor
  if val instanceof Immutable.List
    array-cursor @_root, null, val.size, path
  else # otherwise object-cursor
    object-cursor @_root, null, path

# Get the dereferenced (actual) value of the cursor's view
Cursor.prototype.deref = ->
  data = this.raw!

  if data and data.toJS then data.toJS! else data

# Get the data structure the cursor points to
Cursor.prototype.raw = ->
  @_root._data.get-in @_path

# Update a cursor, with an update buffer to allow recursive updates.
Cursor.prototype.update = (updater) ->
  updates = @_root._updates
  updates.push updater
  return unless updates.length < 2
  cur = this
  until empty updates
    cur = perform-update cur, (first updates)
    updates.shift!
  cur

# Update a cursor recursively, until a condition is met, then notify listeners.
Cursor.prototype.transform = (condition, updater) ->
  x = this
  until condition x
    x := perform-update x, updater, false
  @update -> x.deref!

# Attach an on-change handler to the cursor
Cursor.prototype.on-change = (cbk) ->
  key = join '.', @_path
  @_root._listeners[key] ||= []
  @_root._listeners[key].push cbk

# Compare equality of two cursors' raw data
Cursor.prototype.eq = (cur) ->
  @raw! === cur.raw!

# Split array and object cursors
module.exports = make-cursor = (data) ->
  if is-type 'Array', data
    array-cursor null, data, data.length, []
  else
    object-cursor null, data, []
