require!  <[ ../src/default-config bluebird path fs ]>

describe "config" (_) ->
  describe "to object" (_) ->
    it "derefs the same on any level" ->
      name = data.get \person.first_name

      expect name.deref! .toBe raw-data.person.first_name
