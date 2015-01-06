require! '../src/cursor'

raw-data =
  person:
    first_name: "John"
    last_name: "Johnson"
    age: 35
    pets:
      * animal: "cat"
        name: "Tom"
      * animal: "dog"
        name: "Huckleberry"

data = cursor raw-data

describe "cursor" (_) ->
  describe "to object" (_) ->
    it "derefs the same on any level" ->
      name = data.get \person.first_name

      expect name.deref! .toBe raw-data.person.first_name

    it "doesn't affect original data when the derefed data is changed" ->
      person = data.get \person
      person.deref!.first_name = "Dan"

      expect data.deref!.person.first_name .toBe "John"

  describe "to array" (_) ->
    it "derefs a array item" ->
      tom = data.get \person.pets.0

      expect tom.deref!.name .toBe "Tom"

    it "iterates over an array cursor as if it was a simple array" ->
      names = (data.get \person.pets ) |> map (.deref!.name)

      expect names.0 .toBe "Tom"
      expect names.1 .toBe "Huckleberry"

  describe "stateful updates" (_) ->
    it "updates with a callback" ->
      data = cursor raw-data

      name = data.get \person.first_name
      name.update -> "Bob"

      expect data.deref!.person.first_name .toBe "Bob"

    it "provides current value on update" ->
      data = cursor raw-data

      age = data.get \person.age
      age.update -> it + 1

      expect data.deref!.person.age .toBe 36

    it "allows for larger cumulative updates" ->
      data = cursor raw-data
      pets = data.get \person.pets

      pets.update ->
        [
          * animal: "cat"
            name: "Professor Catus"
          * animal: "dog"
            name: "Baron Woofson"
        ]

      expect (pets.get \0.name .deref!) .toBe "Professor Catus"
      expect (pets.get \1.name .deref!) .toBe "Baron Woofson"

  describe "observation" (_) ->
    it "notifies on change to a path" ->
      name = data.get \person.first_name

      observer = jasmine.create-spy "observer"
      name.on-change observer

      name.update -> "Dave"

      expect observer .to-have-been-called-with "Dave"

    it "notifies on all parents with the respective value" ->
      data = cursor raw-data

      person = data.get \person
      name = person.get \first_name

      person-observer = jasmine.create-spy "person-observer"
      person.on-change person-observer

      name-observer = jasmine.create-spy "name-observer"
      name.on-change name-observer

      name.update -> "Dave"

      expect name-observer .to-have-been-called-with "Dave"

      payload = person-observer.calls.args-for 0 .0
      expect payload.first_name .toBe "Dave"

    it "notifies on all parents even with a list in the path" ->
      data = cursor raw-data

      pets = data.get \person.pets
      cat-name = pets.get \0.name

      pets-observer = jasmine.create-spy "pets-observer"
      pets.on-change pets-observer

      cat-name.update -> "Professor Catus"

      payload = pets-observer.calls.args-for 0 .0
      expect payload.0.name .toBe 'Professor Catus'
