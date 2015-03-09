(function(){
  var bluebird, routes, cursor, dom, serverRendering, span, appComponent;
  bluebird = require('bluebird');
  routes = require('./routes');
  cursor = require('./cursor');
  dom = require('./dom');
  serverRendering = require('./server-rendering');
  span = dom.span;
  appComponent = React.createFactory(React.createClass({
    displayName: 'reflex-application',
    getInitialState: function(){
      return {
        component: this.props.component,
        context: this.props.context,
        appState: this.props.initialState
      };
    },
    render: function(){
      var that;
      if (that = this.state.component) {
        return React.createElement(that, {
          context: this.state.context,
          appState: this.state.appState
        });
      } else {
        return span("Page not found.");
      }
    }
  }));
  module.exports = {
    create: function(config){
      return {
        start: function(){
          var path, rootDomNode, serverState, initialState, ref$, routeComponent, context, _, rootElement, root;
          path = location.pathname + location.search + location.hash;
          rootDomNode = document.getElementById("application");
          serverState = JSON.parse(rootDomNode.getAttribute('data-reflex-app-state'));
          initialState = cursor(serverState || config.getInitialState());
          ref$ = routes.resolve(path, config.routes()), routeComponent = ref$[0], context = ref$[1], _ = ref$[2];
          rootElement = appComponent({
            initialState: initialState,
            component: routeComponent,
            context: context
          });
          config.start(initialState);
          root = React.render(rootElement, rootDomNode);
          initialState.onChange(function(){
            return root.setState({
              appState: initialState
            });
          });
          return routes.start(config.routes(), root, initialState);
        },
        render: function(path){
          var appState, ref$, routeComponent, context, routeInit, rootElement, transaction;
          appState = cursor(config.getInitialState());
          ref$ = routes.resolve(path, config.routes()), routeComponent = ref$[0], context = ref$[1], routeInit = ref$[2];
          rootElement = appComponent({
            initialState: appState,
            component: routeComponent,
            context: context
          });
          transaction = appState.startTransaction();
          config.start(appState);
          if (routeInit) {
            routeInit(appState, context);
          }
          return appState.endTransaction(transaction).then(function(){
            return [appState.deref(), React.renderToString(rootElement)];
          });
        },
        processForm: function(path, postData){
          var appState, ref$, routeComponent, context, routeInit, rootElement, transaction, location;
          appState = cursor(config.getInitialState());
          ref$ = routes.resolve(path, config.routes()), routeComponent = ref$[0], context = ref$[1], routeInit = ref$[2];
          rootElement = appComponent({
            initialState: appState,
            component: routeComponent,
            context: context
          });
          transaction = appState.startTransaction();
          config.start(appState);
          if (routeInit) {
            routeInit(appState, context);
          }
          location = serverRendering.processForm(rootElement, appState, postData, path);
          return appState.endTransaction(transaction).then(function(){
            var body;
            body = !location ? React.renderToString(rootElement) : null;
            return [appState.deref(), body, location];
          });
        }
      };
    }
  };
}).call(this);
