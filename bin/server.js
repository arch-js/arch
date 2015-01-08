#!/usr/bin/env node

require('LiveScript');
var path = require('path');
var server = require('../src/server');

var appPath = process.env.REFLEX_APP || path.resolve('.');
var app = require(path.join(path.relative(__dirname, appPath), 'app/app.ls'));

server.run(app, process.env.REFLEX_PORT || 3000, path.join(appPath, 'dist'), path.join(appPath, 'app', 'layouts'));
