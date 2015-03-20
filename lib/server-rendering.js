(function(){
  var ref$, difference, filter, first, keys, Obj, ReactServerRenderingTransaction, ReactDefaultBatchingStrategy, ReactUpdates, testUtils, redirectLocation, configureReact, renderTree, extractElements, extractRoute, fakeEvent, changeInputs, submitForm, processForm, routeMetadata, resetRedirect, redirect, toString$ = {}.toString;
  ref$ = require('prelude-ls'), difference = ref$.difference, filter = ref$.filter, first = ref$.first, keys = ref$.keys, Obj = ref$.Obj;
  ReactServerRenderingTransaction = require('react/lib/ReactServerRenderingTransaction');
  ReactDefaultBatchingStrategy = require('react/lib/ReactDefaultBatchingStrategy');
  ReactUpdates = require('react/lib/ReactUpdates');
  testUtils = React.addons.TestUtils;
  redirectLocation = null;
  configureReact = function(){
    ReactDefaultBatchingStrategy.isBatchingUpdates = true;
    ReactUpdates.injection.injectReconcileTransaction(ReactServerRenderingTransaction);
    return ReactUpdates.injection.injectBatchingStrategy(ReactDefaultBatchingStrategy);
  };
  renderTree = function(element, depth){
    var transaction, instance;
    depth == null && (depth = 0);
    transaction = ReactServerRenderingTransaction.getPooled(true);
    instance = new element.type(element.props);
    instance.construct(element);
    try {
      transaction.perform(function(){
        return instance.mountComponent("canBeAynthingWhee", transaction, depth);
      });
    } finally {
      ReactServerRenderingTransaction.release(transaction);
    }
    return instance;
  };
  extractElements = function(path, postData, instance){
    var inputNames, forms, inputs, form;
    inputNames = keys(postData);
    forms = testUtils.findAllInRenderedTree(instance, function(it){
      return it._tag === 'form';
    });
    inputs = [];
    form = find(function(form){
      inputs = testUtils.findAllInRenderedTree(form, function(it){
        var ref$;
        return (ref$ = it._tag) === 'input' || ref$ === 'textarea' || ref$ === 'select';
      });
      return any(function(it){
        return in$(it.props.name, inputNames);
      })(
      inputs);
    })(
    filter(function(it){
      return it.props.action === path;
    })(
    forms));
    return [form, inputs];
  };
  extractRoute = function(instance){
    var routes;
    routes = testUtils.findAllInRenderedTree(instance, function(it){
      return it.getLayoutTemplate && toString$.call(it.getLayoutTemplate).slice(8, -1) === 'Function';
    });
    return routes[0];
  };
  fakeEvent = function(element, opts){
    var target, ref$;
    opts == null && (opts = {});
    target = (ref$ = element.props.type) === 'checkbox' || ref$ === 'radio'
      ? {
        checked: !!opts.value
      }
      : {
        value: opts.value
      };
    return {
      stopPropagation: function(){},
      preventDefault: function(){},
      target: target
    };
  };
  changeInputs = function(inputs, postData){
    return each(function(it){
      it.props.onChange(fakeEvent(it, {
        value: postData[it.props.name]
      }));
      return ReactUpdates.flushBatchedUpdates();
    })(
    inputs);
  };
  submitForm = function(form){
    form.props.onSubmit(fakeEvent(form));
    return ReactUpdates.flushBatchedUpdates();
  };
  processForm = function(rootElement, initialState, postData, path){
    var instance, ref$, form, inputs, that;
    configureReact();
    resetRedirect();
    instance = renderTree(rootElement);
    ref$ = extractElements(path, postData, instance), form = ref$[0], inputs = ref$[1];
    changeInputs(inputs, postData);
    submitForm(form);
    if (that = redirectLocation) {
      return that;
    }
    return null;
  };
  routeMetadata = function(rootElement, initialState){
    var instance, route, title, that;
    configureReact();
    instance = renderTree(rootElement, 1);
    route = extractRoute(instance);
    title = (that = route.getTitle) ? that() : "";
    return {
      title: title,
      layout: route.getLayoutTemplate()
    };
  };
  resetRedirect = function(){
    return redirectLocation = null;
  };
  redirect = function(path){
    return redirectLocation = path;
  };
  module.exports = {
    routeMetadata: routeMetadata,
    processForm: processForm,
    redirect: redirect
  };
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
