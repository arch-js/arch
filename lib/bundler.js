(function(){
  var webpack, path, webpackDevServer, ref$, Obj, keys;
  webpack = require('webpack');
  path = require('path');
  webpackDevServer = require('webpack-dev-server');
  ref$ = require('prelude-ls'), Obj = ref$.Obj, keys = ref$.keys;
  exports.bundle = function(paths, watch, changed){
    var entry, browserEnv, config, bundler, lastBuild, server;
    entry = require.resolve(paths.app.abs);
    browserEnv = clone$(process.env);
    browserEnv.REFLEX_ENV = 'browser';
    browserEnv = Obj.map(JSON.stringify)(
    browserEnv);
    config = {
      entry: ['./' + path.basename(entry)],
      context: path.dirname(entry),
      output: {
        libraryTarget: 'var',
        library: 'Application',
        path: path.join(paths.app.abs, paths['public']),
        filename: 'app.js'
      },
      resolve: {
        root: path.join(paths.app.abs, 'node_modules'),
        fallback: path.join(paths.reflex.abs, 'node_modules'),
        extensions: ['', '.ls', '.js', '.jsx']
      },
      resolveLoader: {
        root: path.join(paths.reflex.abs, 'node_modules'),
        fallback: path.join(paths.app.abs, 'node_modules')
      },
      plugins: [new webpack.DefinePlugin({
        'process.env': browserEnv
      })],
      module: {
        preLoaders: [
          {
            test: /\.ls$/,
            loader: 'livescript-loader',
            exclude: /node_modules/
          }, {
            test: /\.(?:js|jsx)$/,
            loader: 'babel-loader',
            exclude: /node_modules/
          }
        ],
        loaders: [],
        postLoaders: []
      }
    };
    if (process.env.NODE_ENV === 'production') {
      config.plugins.push(new webpack.optimize.DedupePlugin());
      config.plugins.push(new webpack.optimize.UglifyJsPlugin());
    }
    if (watch) {
      config.entry.unshift('webpack/hot/dev-server');
      config.entry.unshift('webpack-dev-server/client?http://localhost:3001');
      config.output.publicPath = 'http://localhost:3001/';
      config.module.loaders.push({
        test: /\.(?:js|jsx|ls)$/,
        loader: 'react-hot',
        exclude: /node_modules/
      });
      config.plugins.push(new webpack.HotModuleReplacementPlugin());
      config.plugins.push(new webpack.NoErrorsPlugin());
    }
    bundler = webpack(config);
    if (watch) {
      lastBuild = null;
      bundler.plugin('done', function(stats){
        var diff;
        diff = keys(
        Obj.filter((function(it){
          return it > lastBuild;
        }))(
        stats.compilation.fileTimestamps));
        changed(diff);
        return lastBuild = stats.endTime;
      });
      bundler.plugin('error', function(err){
        return console.log(err);
      });
      server = new webpackDevServer(bundler, {
        filename: 'app.js',
        contentBase: path.join(paths.app.abs, paths['public']),
        hot: true,
        quiet: true,
        noInfo: false,
        watchDelay: 200
      });
      return server.listen(3001, 'localhost');
    } else {
      return bundler.run(function(err, stats){
        return console.log('Bundled app.js');
      });
    }
  };
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);
