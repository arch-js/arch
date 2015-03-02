(function(){
  var react, routes, dom, cursor, span;
  react = require('react');
  routes = require('./routes');
  dom = require('./dom');
  cursor = require('./cursor');
  span = dom.span;
  module.exports = {
    create: function(config){
      return {
        root: process.env.REFLEX_ENV === 'browser' ? config.root || document.getElementById('application') || document.body : void 8,
        type: react.createClass({
          displayName: 'reflex-application-root',
          render: function(){
            var that, ref$;
            if (that = this.props.component) {
              return react.createElement(that.deref(), {
                state: (ref$ = this.props).state,
                context: ref$.context
              });
            } else {
              return span('Page not found');
            }
          }
        }),
        element: function(){
          return react.createElement(this.type, {
            component: this.state.get('component'),
            context: this.state.get('context'),
            state: this.state.get('state')
          });
        },
        render: function(){
          return react.render(this.element(), this.root);
        },
        toString: function(){
          return react.renderToString(this.element());
        },
        state: null,
        _routes: config.routes(),
        start: function(url){
          var state, ref$, component, context, init, this$ = this;
          url == null && (url = routes.path());
          if (!(process.env.REFLEX_ENV === 'browser' && (state = JSON.parse(this.root.getAttribute('data-reflex-app-state'))))) {
            state = config.getInitialState();
          }
          if (config.start) {
            state = config.start(state);
          }
          ref$ = routes.resolve(url, this._routes), component = ref$[0], context = ref$[1], init = ref$[2];
          if (init) {
            state = init(state);
          }
          this.state = cursor({
            state: state,
            component: component,
            context: context
          });
          if (process.env.REFLEX_ENV === 'browser') {
            routes.start(this._routes, function(component, context, init){
              return this$.state.update(function(data){
                if (init) {
                  data.state = init(data.state);
                }
                return data.component = component, data.context = context, data;
              });
            });
            this.state.onChange(function(newCursor){
              this$.state = newCursor;
              return this$.render();
            });
            return this.render();
          } else {
            return [this.state.get('state').deref(), this.toString()];
          }
        }
      };
    }
  };
}).call(this);
