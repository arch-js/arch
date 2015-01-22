(function(){
  var page, splitUrl, parseQuery, contextFromUrl, slice$ = [].slice;
  page = require('page');
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
  contextFromUrl = function(url, params){
    var ref$, path, qs, hash, query;
    ref$ = splitUrl(url), path = ref$[0], qs = ref$[1], hash = ref$[2];
    query = parseQuery(qs);
    return {
      canonicalPath: url,
      path: path,
      queryString: qs,
      hash: hash,
      query: query,
      params: import$(import$({}, query), params)
    };
  };
  module.exports = {
    define: function(){
      var configs;
      configs = slice$.call(arguments);
      return configs;
    },
    page: function(pattern, componentClass, init){
      return {
        route: new page.Route(pattern),
        component: componentClass,
        init: 'function' === typeof init ? init : void 8
      };
    },
    start: function(configs, rootComponent, appState){
      each(function(config){
        return page.callbacks.push(config.route.middleware(function(ctx){
          var context;
          context = contextFromUrl(ctx.canonicalPath, ctx.params);
          rootComponent.setState({
            component: config.component,
            context: context
          });
          window.scrollTo(0, 0);
          if (config.init) {
            return config.init(appState, context, function(){});
          }
        }));
      })(
      configs);
      if (typeof window.history.replaceState !== 'undefined') {
        return page.start();
      }
    },
    resolve: function(url, config){
      var params, route, context;
      params = [];
      route = find(function(it){
        return it.route.match(url, params);
      })(
      config);
      if (!route) {
        return [null];
      }
      context = contextFromUrl(url, params);
      return [route.component, context, route.init];
    }
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
