(function(){
  var bluebird, cursor, dom, routes, serverRendering, cookie, domUtils, ref$, keys, each, Obj, map, reject, span, appComponent, initAppState, observePageChange;
  bluebird = require('bluebird');
  cursor = require('./cursor');
  dom = require('./dom');
  routes = require('./routes');
  serverRendering = require('./server-rendering');
  cookie = require('cookie');
  domUtils = require('./virtual-dom-utils');
  ref$ = require('prelude-ls'), keys = ref$.keys, each = ref$.each, Obj = ref$.Obj, map = ref$.map, reject = ref$.reject;
  span = dom.span;
  appComponent = React.createFactory(React.createClass({
    displayName: 'arch-application',
    getInitialState: function(){
      return {
        appState: this.props.appState
      };
    },
    lookupComponent: function(){
      var route;
      route = this.state.appState.get('route').deref();
      return routes.getComponent(this.props.routes, route.componentId);
    },
    render: function(){
      var component, that;
      component = this.lookupComponent();
      if (that = component) {
        return React.createElement(that, {
          appState: this.state.appState
        });
      } else {
        return span("Page not found.");
      }
    }
  }));
  initAppState = function(initialState, routeContext, cookies){
    return cursor({
      state: initialState,
      route: routeContext,
      cookies: cookies
    });
  };
  observePageChange = function(rootTree, appState){
    return appState.get('route').onChange(function(route){
      return setTimeout(function(){
        var title, el;
        title = domUtils.routeMetadata(rootTree).title;
        document.title = title;
        if (el = document.getElementById(route.hash)) {
          return window.scrollTo(0, el.getBoundingClientRect().top - document.body.getBoundingClientRect().top);
        } else {
          return window.scrollTo(0, 0);
        }
      }, 0);
    });
  };
  module.exports = {
    create: function(app){
      return {
        start: function(){
          var routeSet, path, rootDomNode, stateNode, serverState, appState, clientCookies, parsedCookies, rootElement, root;
          routeSet = app.routes();
          path = location.pathname + location.search + location.hash;
          rootDomNode = document.getElementById("application");
          stateNode = document.getElementById("arch-state");
          serverState = JSON.parse(stateNode.text);
          appState = serverState
            ? cursor(serverState)
            : (clientCookies = cookie.parse(document.cookie), parsedCookies = map(function(k){
              return cookie.serialize(k, clientCookies[k]);
            })(
            keys(
            clientCookies)), initAppState(app.getInitialState(), routes.resolve(routeSet, pathname), parsedCookies));
          app.start(appState);
          rootElement = appComponent({
            appState: appState,
            routes: routeSet
          });
          root = React.render(rootElement, rootDomNode);
          appState.get('cookies').onChange(function(cookies){
            return each(function(ck){
              return document.cookie = ck;
            })(
            cookies);
          });
          appState.onChange(function(){
            return root.setState({
              appState: appState
            });
          });
          observePageChange(root, appState);
          return routes.start(app.routes(), appState);
        },
        render: function(req, res){
          var path, routeSet, clientCookies, parsedCookies, appState, transaction, rootElement;
          path = req.originalUrl;
          routeSet = app.routes();
          clientCookies = cookie.parse(req.headers.cookie || "");
          parsedCookies = map(function(k){
            return cookie.serialize(k, clientCookies[k]);
          })(
          keys(
          clientCookies));
          appState = initAppState(app.getInitialState(), null, []);
          transaction = appState.startTransaction();
          appState.get('cookies').onChange(function(cookies){
            var newCookies;
            newCookies = reject(function(it){
              return in$(it, parsedCookies);
            })(
            cookies);
            return res.set('Set-Cookie', newCookies);
          });
          app.start(appState);
          appState.get('cookies').update(function(){
            return parsedCookies;
          });
          appState.get('route').update(function(){
            return routes.resolve(routeSet, path);
          });
          rootElement = appComponent({
            appState: appState,
            routes: routeSet
          });
          return appState.endTransaction(transaction).then(function(){
            var meta, body, location;
            meta = serverRendering.routeMetadata(rootElement, appState);
            body = !((location = serverRendering.getRedirect()) && location !== path) ? React.renderToString(rootElement) : null;
            serverRendering.resetRedirect();
            return [meta, appState.deref(), body, location];
          });
        },
        processForm: function(req, res){
          var path, clientCookies, parsedCookies, routeSet, appState, transaction, rootElement, location;
          path = req.originalUrl;
          clientCookies = cookie.parse(req.headers.cookie || "");
          parsedCookies = map(function(k){
            return cookie.serialize(k, clientCookies[k]);
          })(
          keys(
          clientCookies));
          routeSet = app.routes();
          appState = initAppState(app.getInitialState(), null, parsedCookies);
          appState.get('cookies').onChange(function(cookies){
            return res.set('Set-Cookie', cookies);
          });
          transaction = appState.startTransaction();
          app.start(appState);
          appState.get('route').update(function(){
            return routes.resolve(routeSet, path);
          });
          rootElement = appComponent({
            appState: appState,
            routes: routeSet
          });
          location = serverRendering.processForm(rootElement, appState, req.body, path);
          return appState.endTransaction(transaction).then(function(){
            var meta, body;
            meta = serverRendering.routeMetadata(rootElement, appState);
            body = !location ? React.renderToString(rootElement) : null;
            return [meta, appState.deref(), body, location];
          });
        }
      };
    }
  };
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
