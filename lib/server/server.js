(function(){
  var express, path, bluebird, bodyParser, bundler, livescript, register, paths, getConfig, renderBody, ref$, each, values, filter, find, flatten, map, first, archGet, archPost, __template;
  express = require('express');
  path = require('path');
  bluebird = require('bluebird');
  bodyParser = require('body-parser');
  bundler = require('../bundler');
  livescript = require('livescript');
  register = require('babel/register');
  paths = require('./paths');
  getConfig = require('./get-config');
  renderBody = require('./render').renderBody;
  ref$ = require('prelude-ls'), each = ref$.each, values = ref$.values, filter = ref$.filter, find = ref$.find, flatten = ref$.flatten, map = ref$.map, first = ref$.first;
  module.exports = function(opts){
    var options, app, get, post;
    opts == null && (opts = {});
    options = getConfig(opts);
    app = require(paths.app.rel);
    get = function(req, res){
      console.log("GET", req.originalUrl);
      return archGet(app, req.originalUrl, options).spread(function(status, headers, body){
        return res.set({
          'Content-Type': 'text/html; charset=utf-8'
        }).status(status).set(headers).send(body);
      });
    };
    post = function(req, res){
      console.log("POST", req.originalUrl, req.body);
      return archPost(app, req.originalUrl, req.body, options).spread(function(status, headers, body){
        return res.set({
          'Content-Type': 'text/html; charset=utf-8'
        }).status(status).set(headers).send(body);
      });
    };
    return {
      start: function(cb){
        var server, listener;
        server = express().use("/" + options['public'], express['static'](path.join(paths.app.abs, options['public']))).use(bodyParser.urlencoded({
          extended: false
        })).get('*', get).post('*', post);
        bundler.bundle(paths, options.environment === 'development', function(ids){
          var done, id, parents, e;
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
          try {
            return app = require(paths.app.rel);
          } catch (e$) {
            e = e$;
            return console.error('Error in changed files when restarting server');
          }
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
  archGet = function(app, url, options){
    return app.render(url).spread(function(meta, appState, body){
      var html;
      html = renderBody(meta, body, appState, options);
      return [200, {}, html];
    });
  };
  archPost = function(app, url, postData, options){
    return app.processForm(url, postData).spread(function(meta, appState, body, location){
      var html;
      if (!body) {
        return [
          302, {
            'Location': location
          }, ""
        ];
      }
      html = renderBody(meta, body, appState, options);
      return [200, {}, html];
    });
  };
  __template = jade.compileFile(path.join(__dirname, 'index.jade'));
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);