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
  array.get = Cursor.prototype.get
  array.deref = Cursor.prototype.deref
  array.raw = Cursor.prototype.raw
  array.update = Cursor.prototype.update
  array._swap = Cursor.prototype._swap
  array.on-change = Cursor.prototype.on-change

  return array

object-cursor = (root, data, path) ->
  new Cursor root, data, path

notify-listeners = (listeners, path, new-data) !->
  paths = [0 to path.length]
  |> map (-> path |> take it)
  |> reverse
  |> each (path) ->
    key = path |> join '.'

    return unless is-type 'Array', listeners[key]

    listeners[key] |> each ->
      payload = new-data.get-in path
      payload .= toJS! if payload.toJS

      it(payload)

Cursor = (root, data, path) ->
  @_path = path
  @_root = root or this
  @_data = if data then Immutable.fromJS(data) else null
  @_listeners = {}

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
  new-val = cbk this.deref!
  new-val = Immutable.fromJS(new-val) if is-type 'Array', new-val or is-type 'Object', new-val

  unless empty @_path
    new-data = @_root._data.set-in @_path, new-val
  else
    new-data = new-val

  # Swap
  @_root._swap new-data

  # Notify about the change
  notify-listeners @_root._listeners, @_path, new-data

Cursor.prototype._swap = (new-data) ->
  throw "_swap can only be called on the root cursor" unless this is @_root

  @_data = new-data

Cursor.prototype.on-change = (cbk) ->
  key = join '.', @_path
  @_root._listeners[key] ||= []
  @_root._listeners[key].push cbk

module.exports = (data) ->
  if is-type 'Array', data
    array-cursor null, data, data.length, []
  else
    object-cursor null, data, []
