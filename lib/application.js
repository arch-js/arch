(function(){
  var bluebird, routes, cursor, dom, serverRendering, domUtils, span, appComponent, initAppState, observePageChange;
  bluebird = require('bluebird');
  routes = require('./routes');
  cursor = require('./cursor');
  dom = require('./dom');
  serverRendering = require('./server-rendering');
  domUtils = require('./virtual-dom-utils');
  span = dom.span;
  appComponent = React.createFactory(React.createClass({
    displayName: 'reflex-application',
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
  initAppState = function(initialState, routeContext){
    return cursor({
      state: initialState,
      route: routeContext
    });
  };
  observePageChange = function(rootTree, appState){
    return appState.get('route').onChange(function(){
      return setTimeout(function(){
        var title;
        title = domUtils.routeMetadata(rootTree).title;
        document.title = title;
        return window.scrollTo(0, 0);
      }, 0);
    });
  };
  module.exports = {
    create: function(app){
      return {
        start: function(){
          var path, rootDomNode, serverState, routeSet, context, appState, rootElement, root;
          path = location.pathname + location.search + location.hash;
          rootDomNode = document.getElementById("application");
          serverState = JSON.parse(rootDomNode.getAttribute('data-reflex-app-state'));
          routeSet = app.routes();
          context = routes.resolve(routeSet, path);
          appState = serverState
            ? cursor(serverState)
            : initAppState(app.getInitialState(), context);
          app.start(appState);
          rootElement = appComponent({
            appState: appState,
            routes: routeSet
          });
          root = React.render(rootElement, rootDomNode);
          appState.onChange(function(){
            return root.setState({
              appState: appState
            });
          });
          observePageChange(root, appState);
          return routes.start(app.routes(), appState);
        },
        render: function(path){
          var routeSet, context, appState, transaction, rootElement;
          routeSet = app.routes();
          context = routes.resolve(routeSet, path);
          appState = initAppState(app.getInitialState(), context);
          transaction = appState.startTransaction();
          app.start(appState);
          rootElement = appComponent({
            appState: appState,
            routes: routeSet
          });
          return appState.endTransaction(transaction).then(function(){
            var meta;
            meta = serverRendering.routeMetadata(rootElement, appState);
            return [meta, appState.deref(), React.renderToString(rootElement)];
          });
        },
        processForm: function(path, postData){
          var routeSet, context, appState, transaction, rootElement, location;
          routeSet = app.routes();
          context = routes.resolve(routeSet, path);
          appState = initAppState(app.getInitialState(), context);
          transaction = appState.startTransaction();
          app.start(appState);
          rootElement = appComponent({
            appState: appState,
            routes: routeSet
          });
          location = serverRendering.processForm(rootElement, appState, postData, path);
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
}).call(this);
