(function(){
  var express, fs, path, jade, react, bluebird, bundler, ref$, each, values, filter, find, flatten, map, first, __template, readFile, defaults, reflexInterp, reflexRender;
  express = require('express');
  fs = require('fs');
  path = require('path');
  jade = require('jade');
  react = require('react');
  bluebird = require('bluebird');
  bundler = require('./bundler');
  ref$ = require('prelude-ls'), each = ref$.each, values = ref$.values, filter = ref$.filter, find = ref$.find, flatten = ref$.flatten, map = ref$.map, first = ref$.first;
  __template = jade.compileFile(path.join(__dirname, 'index.jade'));
  readFile = bluebird.promisify(fs.readFile);
  defaults = {
    environment: process.env.NODE_ENV || 'development',
    port: 3000,
    paths: {
      app: {
        abs: path.resolve('.'),
        rel: path.relative(__dirname, path.resolve('.'))
      },
      layouts: 'app/layouts',
      reflex: {
        abs: path.dirname(require.resolve("reflex/package.json")),
        rel: path.relative(path.resolve('.'), path.dirname(require.resolve("reflex/package.json")))
      },
      'public': 'dist'
    }
  };
  module.exports = function(options){
    var app, render;
    options == null && (options = defaults);
    app = options.app || require(options.paths.app.rel);
    render = function(req, res){
      console.log(req.originalUrl);
      if (req.method !== 'GET') {
        return next();
      }
      return reflexRender(app, req.originalUrl, options).then(function(it){
        return res.send(it);
      });
    };
    return {
      start: function(cb){
        var server, listener;
        server = express().get('/favicon.ico', function(req, res){
          return res.redirect("/" + options.paths['public'] + "/favicon.ico");
        }).use("/" + options.paths['public'], express['static'](path.join(options.paths.app.abs, options.paths['public']))).get('*', render);
        bundler.bundle(options.paths, options.environment === 'development', function(ids){
          var done, id, parents;
          done = [];
          while (id = first(ids)) {
            parents = map(fn$)(
            flatten(
            filter(fn1$)(
            values(
            require.cache))));
            done.push(id);
            each(fn2$)(
            parents);
            ids.splice(0, 1);
          }
          each(function(it){
            var ref$, ref1$;
            return ref1$ = (ref$ = require.cache)[it], delete ref$[it], ref1$;
          })(
          done);
          return app = require(options.paths.app.rel);
          function fn$(it){
            return it.id;
          }
          function fn1$(it){
            return find(function(it){
              return it.id === id;
            })(
            !in$(it.id, done) && it.children);
          }
          function fn2$(it){
            return ids.push(it);
          }
        });
        if (cb) {
          return listener = server.listen(options.port, function(err){
            console.log('App is listening on', listener.address().port);
            return cb(err, {
              server: server,
              listener: listener
            });
          });
        } else {
          return new bluebird(function(res, rej){
            var listener;
            return listener = server.listen(options.port, function(){
              console.log('App is listening on', listener.address().port);
              return res({
                server: server,
                listener: listener
              });
            });
          });
        }
      }
    };
  };
  reflexInterp = function(template, body){
    return template.toString().replace('{reflex-body}', body);
  };
  reflexRender = function(app, url, options){
    var $, state, body;
    $ = app.start(url);
    state = $[0], body = $[1];
    return readFile(path.join(options.paths.layouts, 'default.html')).then(function(it){
      var bundlePath;
      bundlePath = options.environment === 'development'
        ? "http://localhost:3001/app.js"
        : "/" + options.paths['public'] + "/app.js";
      return reflexInterp(it, __template({
        'public': options.paths['public'],
        bundle: bundlePath,
        body: body,
        state: state
      }));
    }).error(function(){
      throw new Error('Template not found!');
    });
  };
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
