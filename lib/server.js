(function(){
  var express, fs, path, jade, Promise, readFile, interpolateTemplate, handleMethodGet, run;
  express = require('express');
  fs = require('fs');
  path = require('path');
  jade = require('jade');
  Promise = require('bluebird');
  readFile = Promise.promisify(fs.readFile);
  interpolateTemplate = function(template, instantiation){
    return template.toString().replace('{reflex-body}', instantiation);
  };
  handleMethodGet = function(app, url, layoutsPath){
    return app.render(url, function(appState, body){
      return readFile(path.join(layoutsPath, 'default.html')).then(function(template){
        var instantiation;
        instantiation = jade.renderFile(__dirname + "/index.jade", {
          body: body,
          state: appState
        });
        return interpolateTemplate(template, instantiation);
      }).error(function(){
        throw new Error('Template not found');
      });
    });
  };
  run = function(app, port, assetPath, layoutsPath){
    var server;
    console.log("Starting Reflex server...");
    server = express();
    console.log("Serving static assets from", assetPath, "on /dist");
    server.use('/dist', express['static'](assetPath));
    server.get('*', function(request, response){
      console.log("GET ", request.originalUrl);
      return handleMethodGet(app, request.originalUrl, layoutsPath).then(function(template){
        response.send(template);
      });
    });
    server.listen(port);
    return console.log("Server running on port", port);
  };
  module.exports = {
    run: run,
    handleMethodGet: handleMethodGet
  };
}).call(this);
