Immutable = require 'immutable'
{map, take, reverse, each, join, split, is-type, empty, obj-to-pairs} = require 'prelude-ls'

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

object-cursor = (root, data, path) ->
  new Cursor root, data, path

notify-changes = (from, to) ->
  # Diffnotify
  from._root._listeners
  |> obj-to-pairs
  |> each ([path, listeners]) ->
    if n = (if path is "" then to._root else to.get path)
      if !n.eq (if path is "" then from._root else from._root.get path)
        listeners |> each (-> it n)

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

  node

Cursor = (root, data, path) ->
  @_path = path
  @_root = root or this
  @_data = if data then Immutable.fromJS(data) else null
  @_listeners = {}
  @_updates = []

  this

Cursor.prototype.get = (path) ->
  path = @_path ++ (split '.', path)
  val = @_root._data.get-in path
  
  return null unless val

  # if the resulting object is a list, return array-cursor
  if val instanceof Immutable.List
    array-cursor @_root, null, val.size, path
  else # otherwise object-cursor
    object-cursor @_root, null, path

Cursor.prototype.deref = ->
  data = this.raw!

  if data and data.toJS then data.toJS! else data

Cursor.prototype.raw = ->
  @_root._data.get-in @_path

Cursor.prototype.update = (cbk) ->
  perform-update this, cbk

Cursor.prototype.update-until = (condition, cbk) ->
  x = this
  until condition x
    x := perform-update x, cbk, false
  @update -> x.deref!

Cursor.prototype.on-change = (cbk) ->
  key = join '.', @_path
  @_root._listeners[key] ||= []
  @_root._listeners[key].push cbk

Cursor.prototype.eq = (cur) ->
  @raw! === cur.raw!

module.exports = make-cursor = (data) ->
  if is-type 'Array', data
    array-cursor null, data, data.length, []
  else
    object-cursor null, data, []
