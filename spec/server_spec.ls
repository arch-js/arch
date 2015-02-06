require! {
  '../src/server'
  fs
  path
}

describe "server" (_) ->

  describe "template assignment" (_) ->

    var support-templates, app, inst

    before-each !->

      support-templates := "#{__dirname}/support/fixtures"
      app := render: jasmine.create-spy 'spy' .and.call-fake (url, cbk) -> cbk 'app-state', 'body'
      inst := server app: app

    it "calls the method that renders a route to string" !->

      inst.render app, 'url', { layouts: support-templates, public: 'dist' }
      # Test that the method that renders a route to a string has been called
      # with a URL an anonymous function.
      expect app.render .to-have-been-called-with 'url', jasmine.any(Function)

    it "throws an error if the specified template cannot be found" (done) !->

      var failed

      inst.render app, 'url', { layouts: 'non-existant/path', public: 'dist' }
      .then (output) !->
        failed := false
      .catch (e) ->
        failed := true
      .finally ->
        expect failed .to-be true
        done!

    it "interpolates the instantiation partial with the author defined template" (done) !->

      inst.render app, 'app-state', { layouts: support-templates, public: 'dist' }
        .then (template) !->
          fs.read-file path.join(support-templates, 'default-reference.html'), (err, template-reference) !->
            expect template .to-equal template-reference.to-string!
            done!
