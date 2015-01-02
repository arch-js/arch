Immutable = require 'immutable'
global import require 'prelude-ls'

# wraps array in a cursor
array-cursor = (root, data, len, path) ->
  array = [0 til len] |> map ->
    new Cursor(root, null, path ++ [it])

  array._path = path
  array._root = root or this
  array._data = if data then Immutable.fromJS(data) else null

  # Support all the cursor API
  array.deref = Cursor.prototype.deref
  array.get = Cursor.prototype.get
  array.update = Cursor.prototype.update
  array.on-change = Cursor.prototype.on-change
  array._swap = Cursor.prototype._swap


  return array

object-cursor = (root, data, path) ->
  new Cursor root, data, path

notify-listeners = (listeners, path, new-data) ->
  all = [0 to path.length]
  |> map (-> path |> take it)
  |> reverse

  all |> each (path) ->
    key = path |> join '.'

    if is-type 'Array', listeners[key]
      listeners[key] |> each ->
        it(new-data.get-in path)

Cursor = (root, data, path) ->
  @_path = path
  @_root = root or this
  @_data = if data then Immutable.fromJS(data) else null
  @_listeners = {}

  this

Cursor.prototype._swap = (path, new-data) ->
  throw "_swap can only be called on the root cursor" unless this is @_root

  @_data = new-data

Cursor.prototype.deref = ->
  data = @_root._data.get-in @_path

  if data and data.toJS then data.toJS! else data

Cursor.prototype.get = (path) ->
  path = @_path ++ (split '.', path)
  val = @_root._data.get-in path

  # if the resulting object is a list, return array-cursor
  if val instanceof Immutable.List
    array-cursor @_root, null, val.size, path
  else # otherwise object-cursor
    object-cursor @_root, null, path

Cursor.prototype.update = (cbk) ->
  new-val = cbk this.deref!
  new-val = Immutable.fromJS(new-val) if is-type 'Array', new-val or is-type 'Object', new-val

  unless empty @_path
    new-data = @_root._data.set-in @_path, new-val
  else
    new-data = new-val

  # Swap
  @_root._swap @_path, new-data

  # Notify about the change
  notify-listeners @_root._listeners, @_path, new-data

Cursor.prototype.on-change = (cbk) ->
  key = join '.', @_path
  @_root._listeners[key] ||= []
  @_root._listeners[key].push cbk

module.exports = (data) ->
  if is-type 'Array', data
    array-cursor null, data, data.length, []
  else
    object-cursor null, data, []
