(function(){
  var express, fs, path, jade, liveify, react, browserify, bluebird, custom, uglifyify, __template, readFile, reflexInterp, reflexRender;
  express = require('express');
  fs = require('fs');
  path = require('path');
  jade = require('jade');
  liveify = require('liveify');
  react = require('react');
  browserify = require('browserify');
  bluebird = require('bluebird');
  custom = require('envify/custom');
  uglifyify = require('uglifyify');
  __template = jade.compileFile(path.join(__dirname, 'index.jade'));
  readFile = bluebird.promisify(fs.readFile);
  module.exports = function(defaults, options){
    var app, bundle, init, render, bundler;
    options == null && (options = {});
    if (typeof defaults === "object") {
      options = defaults;
    }
    if (options.paths && options.paths.app) {
      options.paths.app = path.relative(__dirname, options.paths.app);
    }
    app = options.app || require(options.paths.app);
    bundle = void 8;
    init = function(req, res, next){
      req._reflex = res._reflex = {};
      return next();
    };
    render = function(req, res, next){
      if (req.method !== 'GET') {
        return next();
      }
      return reflexRender(app, req.originalUrl, options.paths.layouts).then(function(it){
        res._reflex.body = it;
        return next();
      });
    };
    bundler = function(req, res, next){
      res.setHeader('Content-Type', 'application/javascript');
      if (bundle) {
        req._reflex.bundle = bundle;
        return next();
      } else {
        console.log('Bundling app.js...');
        return browserify().transform(liveify).transform({
          compress: {
            sequences: true,
            dead_code: true,
            conditionals: true,
            booleans: true,
            unused: true,
            if_return: true,
            join_vars: true,
            drop_console: true
          },
          global: true
        }, uglifyify).transform(custom({
          REFLEX_ENV: 'browser'
        })).require(require.resolve(options.paths.app), {
          expose: 'app'
        }).bundle(function(err, data){
          console.log('Done.');
          req._reflex.bundle = bundle = data;
          return next();
        });
      }
    };
    return {
      start: function(){
        var server;
        server = express().use(init).get('/app.js', bundler).use(render);
        if (defaults !== false) {
          server.get('/app.js', function(req, res){
            res.send(res._reflex.bundle);
            return res.end();
          });
          server.get('*', function(req, res){
            console.log('GET', req.originalUrl);
            res.send(res._reflex.body);
            return res.end();
          });
        }
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
  };
  reflexInterp = function(template, body){
    return template.toString().replace('{reflex-body}', body);
  };
  reflexRender = function(app, url, layouts){
    return app.render(url, function(appState, body){
      return readFile(path.join(layouts, 'default.html')).then(function(it){
        return reflexInterp(it, __template({
          body: body,
          state: appState
        }));
      }).error(function(){
        throw new Error('Template not found!');
      });
    });
  };
}).call(this);
