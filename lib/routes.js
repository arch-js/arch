(function(){
  var domUtils, page, ref$, splitAt, drop, split, map, pairsToObj, each, find, splitUrl, parseQuery, componentId, contextFromUrl, slice$ = [].slice;
  domUtils = require('./virtual-dom-utils');
  page = require('page');
  ref$ = require('prelude-ls'), splitAt = ref$.splitAt, drop = ref$.drop, split = ref$.split, map = ref$.map, pairsToObj = ref$.pairsToObj, each = ref$.each, find = ref$.find;
  splitUrl = function(url){
    var qsIndex, ref$, path, rest, hIndex, qs, hash;
    qsIndex = url.indexOf('?');
    if (qsIndex < 0) {
      return [url, null, null];
    }
    ref$ = splitAt(qsIndex, url), path = ref$[0], rest = ref$[1];
    rest = drop(1, rest);
    hIndex = rest.indexOf('#');
    if (hIndex < 0) {
      return [path, rest, null];
    }
    ref$ = splitAt(hIndex, rest), qs = ref$[0], hash = ref$[1];
    return [path, qs, drop(1, hash)];
  };
  parseQuery = function(query){
    if (!query) {
      return {};
    }
    return pairsToObj(
    map(function(it){
      var ref$, key, value;
      ref$ = split("=")(
      it), key = ref$[0], value = ref$[1];
      return [key, decodeURIComponent(value)];
    })(
    split("&")(
    query)));
  };
  componentId = function(route){
    return route.pattern;
  };
  contextFromUrl = function(url, route, params){
    var ref$, path, qs, hash, query;
    ref$ = splitUrl(url), path = ref$[0], qs = ref$[1], hash = ref$[2];
    query = parseQuery(qs);
    return {
      componentId: componentId(route),
      canonicalPath: url,
      path: path,
      queryString: qs,
      hash: hash,
      query: query,
      params: import$(import$({}, query), params)
    };
  };
  module.exports = {
    running: false,
    define: function(){
      var configs;
      configs = slice$.call(arguments);
      return {
        routes: configs,
        components: pairsToObj(
        map(function(it){
          return [componentId(it), it.component];
        })(
        configs))
      };
    },
    page: function(pattern, componentClass){
      return {
        pattern: pattern,
        route: new page.Route(pattern),
        component: componentClass
      };
    },
    navigate: function(path){
      return page.show(path);
    },
    start: function(routeSet, appState){
      each(function(route){
        return page.callbacks.push(route.route.middleware(function(ctx){
          var context;
          context = contextFromUrl(ctx.canonicalPath, route, ctx.params);
          return appState.get('route').update(function(){
            return context;
          });
        }));
      })(
      routeSet.routes);
      if (typeof window.history.replaceState !== 'undefined') {
        page.start();
      }
      return this.running = true;
    },
    resolve: function(routeSet, url){
      var params, route;
      params = [];
      route = find(function(it){
        return it.route.match(url, params);
      })(
      routeSet.routes);
      if (!route) {
        return null;
      }
      return contextFromUrl(url, route, params);
    },
    getComponent: curry$(function(routeSet, componentId){
      return routeSet.components[componentId];
    })
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function curry$(f, bound){
    var context,
    _curry = function(args) {
      return f.length > 1 ? function(){
        var params = args ? args.concat() : [];
        context = bound ? context || this : this;
        return params.push.apply(params, arguments) <
            f.length && arguments.length ?
          _curry.call(context, params) : f.apply(context, params);
      } : f;
    };
    return _curry();
  }
}).call(this);
