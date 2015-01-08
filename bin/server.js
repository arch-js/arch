#!/usr/bin/env node

require('LiveScript');
var path = require('path');
var server = require('reflex/server');

var appPath = process.env.REFLEX_APP || path.relative(__dirname, path.resolve('.'))
var app = require(path.join(appPath, 'app/app.ls'))

server.run(app, process.env.REFLEX_PORT || 3000, path.join(appPath, 'dist'));