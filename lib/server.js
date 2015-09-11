(function(){
  var express, fs, path, jade, bluebird, bodyParser, bundler, livescript, cookieParser, register, xssFilters, ref$, each, values, filter, find, flatten, map, first, defaults, archGet, archPost, __template, layoutRender;
  express = require('express');
  fs = require('fs');
  path = require('path');
  jade = require('jade');
  bluebird = require('bluebird');
  bodyParser = require('body-parser');
  bundler = require('./bundler');
  livescript = require('livescript');
  cookieParser = require('cookie-parser');
  register = require('babel/register');
  xssFilters = require('xss-filters');
  ref$ = require('prelude-ls'), each = ref$.each, values = ref$.values, filter = ref$.filter, find = ref$.find, flatten = ref$.flatten, map = ref$.map, first = ref$.first;
  defaults = {
    archPath: path.dirname(path.resolve('./node_modules/arch')),
    appPath: path.dirname(path.resolve('./package.json')),
    bundle: true,
    bundlePath: 'http://localhost:3001/app.js',
    environment: process.env.NODE_ENV || 'development',
    port: 3000,
    publicPath: 'dist',
    watch: true
  };
  module.exports = function(options){
    var app, server, get, post;
    options = import$(clone$(defaults), options);
    app = require(options.appPath);
    server = express().use(function(req, res, next){
      req.appState = {};
      return next();
    }).use("/" + options.publicPath, express['static'](path.join(options.appPath, options.publicPath))).use(bodyParser.urlencoded({
      extended: false
    })).use(cookieParser());
    get = function(req, res){
      console.log("GET", req.originalUrl);
      return archGet(app, req, res, options).spread(function(status, headers, body){
        return res.status(status).set(headers).send(body);
      });
    };
    post = function(req, res){
      console.log("POST", req.originalUrl);
      return archPost(app, req, res, options).spread(function(status, headers, body){
        return res.status(status).set(headers).send(body);
      });
    };
    return {
      use: server.use,
      inst: server,
      start: function(cb){
        var startServer;
        server.get('*', get).post('*', post);
        startServer = function(){
          var listener;
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
        };
        if (options.bundle) {
          return bundler.bundle(options, function(ids){
            var done, id, parents, e;
            console.log('bundled');
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
              app = require(options.appPath);
            } catch (e$) {
              e = e$;
              console.error('Error in changed files when restarting server');
            }
            return startServer();
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
        } else {
          return startServer();
        }
      }
    };
  };
  archGet = function(app, req, res, options){
    return app.render(req, res).spread(function(meta, appState, body, location){
      var html;
      if (!body) {
        return [
          302, {
            'Location': location
          }, ""
        ];
      }
      html = layoutRender(meta, body, appState, options);
      return [200, {}, html];
    });
  };
  archPost = function(app, req, res, options){
    return app.processForm(req, res).spread(function(meta, appState, body, location){
      var html;
      if (!body) {
        return [
          302, {
            'Location': location
          }, ""
        ];
      }
      html = layoutRender(meta, body, appState, options);
      return [200, {}, html];
    });
  };
  __template = jade.compileFile(path.join(__dirname, 'index.jade'));
  layoutRender = function(meta, body, appState, options){
    var archBody, layout, title;
    archBody = __template({
      'public': options.publicPath,
      bundle: options.bundlePath,
      body: body,
      state: xssFilters.inHTMLData(
      JSON.stringify(
      appState))
    });
    layout = meta.layout, title = meta.title;
    return layout({
      body: archBody,
      title: title
    });
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
