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
          config.start(initialState, function(){});
          root = React.render(rootElement, rootDomNode);
          initialState.onChange(function(){
            return root.setState({
              appState: initialState
            });
          });
          return routes.start(config.routes(), root, initialState);
        },
        render: function(path){
          return new bluebird(function(res, rej){
            var initialState, ref$, routeComponent, context, routeInit, rootElement;
            initialState = cursor(config.getInitialState());
            ref$ = routes.resolve(path, config.routes()), routeComponent = ref$[0], context = ref$[1], routeInit = ref$[2];
            rootElement = appComponent({
              initialState: initialState,
              component: routeComponent,
              context: context
            });
            return config.start(initialState, function(){
              if (!routeInit) {
                return res([initialState.deref(), React.renderToString(rootElement)]);
              }
              return routeInit(initialState, context, function(){
                return res([initialState.deref(), React.renderToString(rootElement)]);
              });
            });
          });
        },
        processForm: function(path, postData){
          return new bluebird(function(res, rej){
            var initialState, ref$, routeComponent, context, routeInit, rootElement;
            initialState = cursor(config.getInitialState());
            ref$ = routes.resolve(path, config.routes()), routeComponent = ref$[0], context = ref$[1], routeInit = ref$[2];
            rootElement = appComponent({
              initialState: initialState,
              component: routeComponent,
              context: context
            });
            return config.start(initialState, function(){
              if (!routeInit) {
                return res(serverRendering.processForm(rootElement, initialState, postData, path));
              }
              return routeInit(initialState, context, function(){
                return res(serverRendering.processForm(rootElement, initialState, postData, path));
              });
            });
          });
        }
      };
    }
  };
}).call(this);
