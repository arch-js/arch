#!/usr/bin/env node

var path = require('path');
var server = require('../server');

var appPath = process.env.REFLEX_APP || path.resolve('.');

var app = server({
  port: process.env.REFLEX_PORT || 3000,
  paths: {
    app: appPath,
    layouts: 'app/layouts',
    public: 'dist'
  }
}).start();

