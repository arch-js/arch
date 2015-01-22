(function(){
  var react, routes, cursor, appComponent;
  react = require('react');
  routes = require('./routes');
  cursor = require('./cursor');
  import$(global, require('prelude-ls'));
  appComponent = react.createFactory(react.createClass({
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
        return that({
          context: this.state.context,
          appState: this.state.appState
        });
      } else {
        return null;
      }
    }
  }));
  module.exports = {
    create: function(config){
      return {
        start: function(){
          var routeConfig, rootElement, initialState, path, ref$, routeComponent, context, routeInit, appState, rootComponent, root;
          routeConfig = config.routes();
          rootElement = document.getElementById("application");
          initialState = JSON.parse(rootElement.getAttribute('data-reflex-app-state'));
          path = location.pathname + location.search + location.hash;
          ref$ = routes.resolve(path, routeConfig), routeComponent = ref$[0], context = ref$[1], routeInit = ref$[2];
          appState = cursor(initialState || config.getInitialState());
          config.start(appState, function(){});
          rootComponent = appComponent({
            initialState: appState,
            component: routeComponent,
            context: context
          });
          root = react.render(rootComponent, rootElement);
          appState.onChange(function(){
            return root.setState({
              appState: appState
            });
          });
          return routes.start(config.routes(), root, appState);
        },
        render: function(path, cbk){
          var routeConfig, initialState, ref$, routeComponent, context, routeInit, rootComponent;
          routeConfig = config.routes();
          initialState = cursor(config.getInitialState());
          ref$ = routes.resolve(path, routeConfig), routeComponent = ref$[0], context = ref$[1], routeInit = ref$[2];
          if (!routeComponent) {
            return cbk(initialState.deref(), "404");
          }
          rootComponent = appComponent({
            initialState: initialState,
            component: routeComponent,
            context: context
          });
          return config.start(initialState, function(){
            if (!routeInit) {
              return cbk(initialState.deref(), react.renderToString(rootComponent));
            }
            return routeInit(initialState, context, function(){
              return cbk(initialState.deref(), react.renderToString(rootComponent));
            });
          });
        }
      };
    }
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
