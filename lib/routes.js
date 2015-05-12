(function(){
  var page, URL, ref$, splitAt, drop, split, map, pairsToObj, each, find, componentId, contextFromUrl, slice$ = [].slice;
  page = require('page');
  URL = require('url');
  ref$ = require('prelude-ls'), splitAt = ref$.splitAt, drop = ref$.drop, split = ref$.split, map = ref$.map, pairsToObj = ref$.pairsToObj, each = ref$.each, find = ref$.find;
  componentId = function(route){
    return route.pattern;
  };
  contextFromUrl = function(url, route, params){
    var ctx;
    ctx = URL.parse(url, true);
    return {
      componentId: componentId(route),
      canonicalPath: url,
      path: ctx.pathname,
      queryString: ctx.search ? drop(1, ctx.search) : null,
      hash: ctx.hash ? drop(1, ctx.hash) : null,
      query: ctx.query,
      params: import$(import$({}, ctx.query), params)
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
