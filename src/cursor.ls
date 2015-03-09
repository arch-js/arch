Immutable = require 'immutable'
require! 'bluebird'

{map, take, reverse, each, join, split, is-type, empty} = require 'prelude-ls'

UpdateTransaction = !->
  @promises = []

is-promise = ->
  it and it.then and typeof! it.then is 'Function'

# wraps array in a cursor
array-cursor = (root, data, len, path) ->
  array = [0 til len] |> map ->
    new Cursor(root, null, path ++ [it])

  array._path = path
  array._root = root or this
  array._data = if data then Immutable.fromJS(data) else null
  array._listeners = {}
  array._transactions = []
  array._updates = []

  # Support all the cursor API
  array{get, deref, raw, update, _swap, on-change} = Cursor.prototype

  return array

object-cursor = (root, data, path) ->
  new Cursor root, data, path

notify-listeners = (listeners, transactions, path, new-data) !->
  paths = [0 to path.length]
  |> map (-> path |> take it)
  |> reverse
  |> each (path) ->
    key = path |> join '.'

    return unless is-type 'Array', listeners[key]

    listeners[key] |> each ->
      payload = new-data.get-in path
      payload .= toJS! if payload.toJS

      maybe-promise = it(payload)

      if is-promise maybe-promise
        transactions |> each -> it.promises.push maybe-promise

flush-updates = (updates) ->
  while updates.length > 0
    [cursor, update] = updates[0]
    perform-update cursor, update

    updates.shift!

perform-update = (cursor, update) ->
  old-val = cursor.raw!

  new-val = update cursor.deref!
  new-val = Immutable.fromJS(new-val) if is-type 'Array', new-val or is-type 'Object', new-val

  return if old-val is new-val
  return if Immutable.is(old-val, new-val)

  new-data = if empty cursor._path
    new-val
  else
    cursor._root._data.set-in cursor._path, new-val

  # Swap
  cursor._root._swap new-data

  # Notify about the change
  notify-listeners cursor._root._listeners, cursor._root._transactions, cursor._path, new-data

Cursor = (root, data, path) ->
  @_path = path
  @_root = root or this
  @_data = if data then Immutable.fromJS(data) else null
  @_listeners = {}
  @_transactions = []
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
  updates = @_root._updates
  updates.push [this, cbk]
  return unless updates.length < 2

  until empty updates
    [cursor, update] = updates[0]
    perform-update cursor, update

    updates.shift!

Cursor.prototype._swap = (new-data) ->
  throw "_swap can only be called on the root cursor" unless this is @_root

  @_data = new-data

Cursor.prototype.on-change = (cbk) ->
  key = join '.', @_path
  @_root._listeners[key] ||= []
  @_root._listeners[key].push cbk

Cursor.prototype.start-transaction = ->
  t = new UpdateTransaction!
  @_root._transactions.push t

  t

Cursor.prototype.end-transaction = (transaction) ->
  i = @_root._transactions.index-of transaction
  throw new Error "Transaction isn't running" if i < 0

  return bluebird.resolve! if empty transaction.promises

  bluebird.all transaction.promises

module.exports = (data) ->
  if is-type 'Array', data
    array-cursor null, data, data.length, []
  else
    object-cursor null, data, []
