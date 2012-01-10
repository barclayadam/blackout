(function() {

  /* 
   Blackout JavaScript library v0.1.0
   (c) Adam Barclay
  */

  var HistoryManager, Menu, MenuItem, PagerModel, Route, SitemapNode, TreeNode, TreeViewModel, createErrorKey, currentEnableBindingUpdate, currentPartsValueAccessor, currentValueBinding, draggableModel, emptyValue, getType, getValidationFailureMessage, handlers, hasValue, simpleHandler, toOrderDirection, validateValue;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  window.bo = {};

  window.bo.ui = {};

  window.bo.arg = {
    ensureDefined: function(argument, argumentName) {
      if (argument === void 0) {
        throw "Argument '" + argumentName + "' must be defined.";
      }
    },
    ensureFunction: function(argument, argumentName) {
      if (_.isFunction(argument === false)) {
        throw "Argument '" + argumentName + "' must be a function. '" + argument + "' was passed.";
      }
    },
    ensureString: function(argument, argumentName) {
      if (typeof argument !== 'string') {
        throw "Argument '" + argumentName + "' must be a string. '" + argument + "' was passed.";
      }
    },
    ensureNumber: function(argument, argumentName) {
      if (typeof argument !== 'number') {
        throw "Argument '" + argumentName + "' must be a number. '" + argument + "' was passed.";
      }
    }
  };

  window.bo.exportSymbol = function(path, object) {
    var target, token, tokens, _i, _len, _ref;
    tokens = path.split('.');
    target = window;
    _ref = tokens.slice(0, (tokens.length - 2) + 1 || 9e9);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      token = _ref[_i];
      target = target[token] || (target[token] = {});
    }
    return target[tokens[tokens.length - 1]] = object;
  };

  if (!window.console) {
    window.console = {
      log: function() {}
    };
  }

  if (!Array.prototype.sum) {
    Array.prototype.sum = function() {
      var e, sum, _i, _len;
      sum = 0;
      for (_i = 0, _len = this.length; _i < _len; _i++) {
        e = this[_i];
        sum += e;
      }
      return sum;
    };
  }

  if (!String.prototype.startsWith) {
    String.prototype.startsWith = function(value) {
      return this.lastIndexOf(value, 0) === 0;
    };
  }

  if (!String.prototype.endsWith) {
    String.prototype.endsWith = function(suffix) {
      return (this.indexOf(suffix, this.length - suffix.length)) !== -1;
    };
  }

  window.bo.utils = {
    addTemplate: function(name, template) {
      if (jQuery("#" + name).length === 0) {
        return jQuery('head').append("<script type='text/x-jquery-tmpl' id='" + name + "'>" + template + "</script>");
      }
    },
    fromCamelToTitleCase: function(str) {
      return str.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/\b([A-Z]+)([A-Z])([a-z])/, '$1 $2$3').replace(/^./, function(s) {
        return s.toUpperCase();
      });
    },
    asObservable: function(value) {
      if (ko.isObservable(value)) return value;
      if (_.isArray(value)) {
        return ko.observableArray(value);
      } else {
        return ko.observable(value);
      }
    },
    toCssClass: function(value) {
      value = ko.utils.unwrapObservable(value);
      if (value != null) return value.replace(' ', '-').toLowerCase();
    },
    joinObservables: function() {
      var masterObservable, o, other, others, propagating, _i, _j, _len, _len2, _results;
      masterObservable = arguments[0], others = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      for (_i = 0, _len = others.length; _i < _len; _i++) {
        other = others[_i];
        other(masterObservable());
      }
      propagating = false;
      masterObservable.subscribe(function(newValue) {
        var o, _j, _len2;
        if (!propagating) {
          propagating = true;
          for (_j = 0, _len2 = others.length; _j < _len2; _j++) {
            o = others[_j];
            o(newValue);
          }
          return propagating = false;
        }
      });
      _results = [];
      for (_j = 0, _len2 = others.length; _j < _len2; _j++) {
        o = others[_j];
        _results.push(o.subscribe(function(newValue) {
          return masterObservable(newValue);
        }));
      }
      return _results;
    },
    resolvedPromise: function() {
      var deferred;
      deferred = new jQuery.Deferred();
      deferred.resolve();
      return deferred;
    },
    isElementEnabled: function(allBindingsAccessor) {
      var disabledBinding, enabledBinding;
      enabledBinding = allBindingsAccessor().enabled;
      disabledBinding = allBindingsAccessor().disabled;
      return ko.utils.unwrapObservable((enabledBinding != null ? enabledBinding : true) && !ko.utils.unwrapObservable(disabledBinding != null ? disabledBinding : false));
    }
  };

  bo.Bus = (function() {

    function Bus(busOptions) {
      this.busOptions = busOptions;
      this._initBus();
    }

    Bus.prototype._initBus = function() {
      if (!(this.busOptions != null)) {
        this.busOptions = {
          global: false,
          log: true
        };
      }
      this._subscribers = {};
      this._currentToken = 0;
      return this._initBus = function() {};
    };

    Bus.prototype.clearAll = function() {
      return this._subscribers = {};
    };

    Bus.prototype.subscribe = function(eventName, func) {
      var tokenToUse;
      var _this = this;
      bo.arg.ensureString(eventName, 'eventName');
      bo.arg.ensureFunction(func, 'func');
      this._initBus();
      if (this._subscribers[eventName] === void 0) {
        this._subscribers[eventName] = {};
      }
      this._currentToken = ++this._currentToken;
      tokenToUse = this._currentToken;
      this._subscribers[eventName][tokenToUse] = func;
      return {
        unsubscribe: function() {
          return delete _this._subscribers[eventName][tokenToUse];
        }
      };
    };

    Bus.prototype.publish = function() {
      var args, canContinue, e, eventName, events, indexOfSeparator, subscriber, t, _i, _len, _ref;
      eventName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      bo.arg.ensureString(eventName, 'eventName');
      this._initBus();
      if (this.busOptions.log === true) {
        if (this.busOptions.global === false) {
          console.log("Publishing " + eventName + " (local)");
        } else {
          console.log("Publishing " + eventName);
        }
      }
      if (this.busOptions.global === false) bo.bus.publish(eventName, args);
      indexOfSeparator = -1;
      events = [eventName];
      while (eventName = eventName.substring(0, eventName.lastIndexOf(':'))) {
        events.push(eventName);
      }
      for (_i = 0, _len = events.length; _i < _len; _i++) {
        e = events[_i];
        _ref = this._subscribers[e] || {};
        for (t in _ref) {
          subscriber = _ref[t];
          canContinue = subscriber.apply(this, args);
          if (canContinue === false) return false;
        }
      }
      return true;
    };

    return Bus;

  })();

  bo.bus = new bo.Bus({
    global: true,
    log: true
  });

  ko.extenders.publishable = function(target, eventName) {
    var result;
    result = ko.computed({
      read: target,
      write: function(value) {
        var currentValue, shouldChange;
        currentValue = target();
        target(value);
        shouldChange = bo.bus.publish(eventName, value);
        if (shouldChange === false) return target(currentValue);
      }
    });
    return result;
  };

  ko.extenders.addressable = function(target, paramNameOrOptions) {
    var isPersistent, paramName;
    if (typeof paramNameOrOptions === "string") {
      paramName = paramNameOrOptions;
      isPersistent = false;
    } else {
      paramName = paramNameOrOptions.name;
      isPersistent = paramNameOrOptions.persistent;
    }
    target.subscribe(function(newValue) {
      return bo.routing.manager.setQueryParameter(paramName, newValue, isPersistent);
    });
    jQuery(window).bind("statechange", function() {
      var newValue;
      newValue = bo.query.get(paramName);
      if (target() !== newValue) return target(newValue);
    });
    target(bo.query.get(paramName));
    return target;
  };

  ko.extenders.onDemand = function(target, loader) {
    target.subscribe(function() {
      target.loaded(true);
      return target.isLoading(false);
    });
    target.isLoading = ko.observable(false);
    target.loaded = ko.observable(false);
    target.load = function(loadedCallback) {
      var subscription;
      if (!target.loaded()) {
        target.isLoading(true);
        if ((loadedCallback != null)) {
          subscription = target.loaded.subscribe(function() {
            loadedCallback();
            return subscription.dispose();
          });
        }
        return loader(target);
      } else {
        if (loadedCallback != null) return loadedCallback();
      }
    };
    target.refresh = function() {
      target.loaded(false);
      return target.load();
    };
    return target;
  };

  ko.extenders.async = function(target, loaderOrOptions) {
    var asyncLoader, options;
    if (_.isFunction(loaderOrOptions)) {
      options = {
        callback: loaderOrOptions,
        throttle: 250
      };
    } else {
      options = loaderOrOptions;
    }
    target.subscribe(function() {
      return target.isLoading(false);
    });
    target.isLoading = ko.observable(false);
    asyncLoader = ko.computed(function() {
      target.isLoading(true);
      return options.callback(target);
    });
    if (options.throttle > 0) {
      asyncLoader.extend({
        throttle: options.throttle
      });
    }
    return target;
  };

  createErrorKey = function(propertyName, parent) {
    if (parent !== '') {
      return "" + parent + "." + propertyName;
    } else {
      return propertyName;
    }
  };

  hasValue = function(value) {
    return (value != null) && value !== '';
  };

  emptyValue = function(value) {
    return !hasValue(value);
  };

  getValidationFailureMessage = function(propertyName, propertyValue, model, ruleName, ruleOptions) {
    var messagePropertyName, _ref, _ref2, _ref3;
    messagePropertyName = "" + ruleName + "Message";
    if (((_ref = model.modelValidationRules) != null ? (_ref2 = _ref[propertyName]) != null ? _ref2[messagePropertyName] : void 0 : void 0) != null) {
      return model.modelValidationRules[propertyName][messagePropertyName];
    } else if ((propertyValue != null ? (_ref3 = propertyValue.validationRules) != null ? _ref3[messagePropertyName] : void 0 : void 0) != null) {
      return propertyValue.validationRules[messagePropertyName];
    } else if (bo.messages[ruleName] != null) {
      return bo.messages[ruleName](propertyName, model, ruleOptions);
    } else {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " validation failed";
    }
  };

  validateValue = function(propertyName, propertyValue, propertyRules, model) {
    var errors, isValid, ruleName, ruleOptions, unwrappedPropertyValue;
    errors = [];
    propertyRules = propertyRules || (propertyValue != null ? propertyValue.validationRules : void 0);
    unwrappedPropertyValue = ko.utils.unwrapObservable(propertyValue);
    if (propertyRules) {
      for (ruleName in propertyRules) {
        ruleOptions = propertyRules[ruleName];
        if (!(!(ruleName.endsWith('Message')))) continue;
        if (!(bo.validators[ruleName] != null)) {
          throw new Error("'" + ruleName + "' is not a validator. Must be defined as method on bo.validators");
        }
        isValid = bo.validators[ruleName](unwrappedPropertyValue, model, ruleOptions);
        if (!isValid) {
          errors.push(getValidationFailureMessage(propertyName, propertyValue, model, ruleName, ruleOptions));
        }
      }
    }
    if ((propertyValue != null ? propertyValue.errors : void 0) != null) {
      propertyValue.errors(errors);
    }
    return errors;
  };

  bo.validate = function(modelToValidate, parentProperty) {
    var errors;
    if (parentProperty == null) parentProperty = '';
    errors = {};
    ko.computed(function() {
      var arrayItem, errorKey, i, model, modelErrors, propertyName, propertyValue, rules, unwrappedPropertyValue, valueValidationErrors, _len;
      model = ko.utils.unwrapObservable(modelToValidate);
      if (model != null) {
        modelErrors = {};
        rules = model.modelValidationRules || {};
        for (propertyName in model) {
          propertyValue = model[propertyName];
          if (!(!_(['modelErrors', 'modelValidationRules', 'validationRules', 'isValid', 'errors']).contains(propertyName))) {
            continue;
          }
          unwrappedPropertyValue = ko.utils.unwrapObservable(propertyValue);
          errorKey = createErrorKey(propertyName, parentProperty);
          valueValidationErrors = validateValue(propertyName, propertyValue, rules[propertyName], model);
          if (valueValidationErrors.length > 0) {
            errors[errorKey] = valueValidationErrors;
            modelErrors[propertyName] = valueValidationErrors;
          }
          if (_.isArray(unwrappedPropertyValue)) {
            for (i = 0, _len = unwrappedPropertyValue.length; i < _len; i++) {
              arrayItem = unwrappedPropertyValue[i];
              _.extend(errors, bo.validate(arrayItem, "" + errorKey + "[" + i + "]"));
            }
          } else if (jQuery.isPlainObject(unwrappedPropertyValue)) {
            _.extend(errors, bo.validate(unwrappedPropertyValue, errorKey));
          }
        }
        if (ko.isWriteableObservable(model.modelErrors)) {
          return model.modelErrors(modelErrors);
        } else {
          return model.modelErrors = modelErrors;
        }
      }
    });
    return errors;
  };

  bo.validatableModel = function(model, modelValidationRules) {
    if (modelValidationRules == null) modelValidationRules = {};
    model.modelErrors = ko.observable({});
    model.isValid = ko.computed(function() {
      return _.isEmpty(model.modelErrors());
    });
    model.modelValidationRules = modelValidationRules;
    return model.validate = function() {
      return bo.validate(model);
    };
  };

  ko.extenders.validatable = function(target, validationRules) {
    target.errors = ko.observable([]);
    target.isValid = ko.computed(function() {
      return target.errors().length === 0;
    });
    target.validationRules = validationRules;
    return target;
  };

  ko.subscribable.fn.validatable = function(validationRules) {
    ko.extenders.validatable(this, validationRules);
    return this;
  };

  bo.validators = {
    required: function(value, model, options) {
      return hasValue(value);
    },
    regex: function(value, model, options) {
      return (emptyValue(value)) || (options.test(value));
    },
    minLength: function(value, model, options) {
      return (emptyValue(value)) || ((value.length != null) && value.length >= options);
    },
    maxLength: function(value, model, options) {
      return (emptyValue(value)) || ((value.length != null) && value.length <= options);
    },
    rangeLength: function(value, model, options) {
      return (bo.validators.minLength(value, model, options[0])) && (bo.validators.maxLength(value, model, options[1]));
    },
    min: function(value, model, options) {
      return (emptyValue(value)) || (value >= options);
    },
    max: function(value, model, options) {
      return (emptyValue(value)) || (value <= options);
    },
    range: function(value, model, options) {
      return (bo.validators.min(value, model, options[0])) && (bo.validators.max(value, model, options[1]));
    }
  };

  bo.messages = {
    required: function(propertyName, model, options) {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " is required.";
    },
    regex: function(propertyName, model, options) {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " is invalid.";
    },
    minLength: function(propertyName, model, options) {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " must be at least " + options + " characters long.";
    },
    maxLength: function(propertyName, model, options) {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " must be no more than " + options + " characters long.";
    },
    rangeLength: function(propertyName, model, options) {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " must be between " + options[0] + " and " + options[1] + " characters long.";
    },
    min: function(propertyName, model, options) {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " must be equal to or greater than " + options + ".";
    },
    max: function(propertyName, model, options) {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " must be equal to or less than " + options + ".";
    },
    range: function(propertyName, model, options) {
      return "" + (bo.utils.fromCamelToTitleCase(propertyName)) + " must be between " + options[0] + " and " + options[1] + ".";
    }
  };

  toOrderDirection = function(order) {
    if (order === 'asc' || order === 'ascending') {
      return 'ascending';
    } else {
      return 'descending';
    }
  };

  bo.DataSource = (function() {

    function DataSource(options) {
      var _this = this;
      this.options = options;
      this.isLoading = ko.observable(false);
      this._hasLoadedOnce = false;
      this._serverPagingEnabled = this.options.serverPaging > 0;
      this._clientPagingEnabled = this.options.clientPaging > 0;
      this.pagingEnabled = this._serverPagingEnabled || this._clientPagingEnabled;
      this._loadedItems = ko.observableArray();
      this.sortedBy = ko.observable();
      this.sorting = ko.computed(function() {
        var sortedBy;
        sortedBy = _this.sortedBy();
        if (sortedBy != null) {
          if (_.isString(sortedBy)) {
            return sortedBy;
          } else if (sortedBy.length > 0) {
            return _.reduce(sortedBy, (function(memo, o) {
              var prop;
              prop = "" + o.name + " " + o.order;
              if (memo) {
                return "" + memo + ", " + prop;
              } else {
                return prop;
              }
            }), '');
          }
        }
      });
      this._sortFunction = ko.observable();
      this.items = ko.computed(function() {
        if (_this._sortFunction() != null) {
          return _this._loadedItems().sort(_this._sortFunction());
        } else {
          return _this._loadedItems();
        }
      });
      if (this.options.searchParameters != null) {
        this.searchParameters = ko.computed(function() {
          return ko.toJS(options.searchParameters);
        });
        this.searchParameters.subscribe(function() {
          if (_this._hasLoadedOnce) return _this.load();
        });
      } else {
        this.searchParameters = ko.observable({});
      }
      this._setupPaging();
      this._setupInitialData();
    }

    DataSource.prototype.getPropertySortOrder = function(propertyName) {
      var ordering, sortedBy;
      sortedBy = this.sortedBy();
      if ((sortedBy != null) && sortedBy.length > 0) {
        ordering = _.find(sortedBy, function(o) {
          return o.name === propertyName;
        });
        return ordering != null ? ordering.order : void 0;
      }
    };

    DataSource.prototype.sort = function() {
      if (!this._serverPagingEnabled) {
        this._sortFunction(function(a, b) {
          return (b < a) - (a < b);
        });
      }
      return this.sortedBy('ascending');
    };

    DataSource.prototype.sortDescending = function() {
      if (!this._serverPagingEnabled) {
        this._sortFunction(function(a, b) {
          return ((b < a) - (a < b)) * -1;
        });
      }
      return this.sortedBy('descending');
    };

    DataSource.prototype.sortBy = function(propertyNames) {
      var properties;
      properties = _(propertyNames.split(',')).map(function(p) {
        var indexOfSpace;
        p = jQuery.trim(p);
        indexOfSpace = p.indexOf(' ');
        if (indexOfSpace > -1) {
          return {
            name: p.substring(0, indexOfSpace),
            order: toOrderDirection(p.substring(indexOfSpace + 1))
          };
        } else {
          return {
            name: p,
            order: 'ascending'
          };
        }
      });
      if (!this._serverPagingEnabled) {
        this._sortFunction(function(a, b) {
          var p, _i, _len;
          for (_i = 0, _len = properties.length; _i < _len; _i++) {
            p = properties[_i];
            if (a[p.name] > b[p.name]) {
              if (p.order === 'ascending') {
                return 1;
              } else {
                return -1;
              }
            }
            if (a[p.name] < b[p.name]) {
              if (p.order === 'ascending') {
                return -1;
              } else {
                return 1;
              }
            }
          }
          return 0;
        });
      }
      return this.sortedBy(properties);
    };

    DataSource.prototype.load = function() {
      var currentPageNumber;
      currentPageNumber = this.pageNumber();
      this.pageNumber(1);
      if (!this._serverPagingEnabled || currentPageNumber === 1) {
        return this._doLoad();
      }
    };

    DataSource.prototype.goTo = function(pageNumber) {
      return this.pageNumber(pageNumber);
    };

    DataSource.prototype.goToFirstPage = function() {
      return this.goTo(1);
    };

    DataSource.prototype.goToLastPage = function() {
      return this.goTo(this.pageCount());
    };

    DataSource.prototype.goToNextPage = function() {
      if (!this.isLastPage()) return this.goTo(this.pageNumber() + 1);
    };

    DataSource.prototype.goToPreviousPage = function() {
      if (!this.isFirstPage()) return this.goTo(this.pageNumber() - 1);
    };

    DataSource.prototype._setupInitialData = function() {
      if ((this.options.provider != null) && _.isArray(this.options.provider)) {
        this._setData(this.options.provider);
        return this.goTo(1);
      }
    };

    DataSource.prototype._setupPaging = function() {
      var _this = this;
      this._lastProviderOptions = -1;
      this.clientPagesPerServerPage = this.options.serverPaging / (this.options.clientPaging || this.options.serverPaging);
      this.pageSize = ko.observable();
      this.pageNumber = ko.observable();
      this.totalCount = ko.observable();
      this.pageItems = ko.computed(function() {
        var end, start;
        if (_this._clientPagingEnabled && _this._serverPagingEnabled) {
          start = ((_this.pageNumber() - 1) % _this.clientPagesPerServerPage) * _this.pageSize();
          end = start + _this.pageSize();
          return _this.items().slice(start, end);
        } else if (_this._clientPagingEnabled) {
          start = (_this.pageNumber() - 1) * _this.pageSize();
          end = start + _this.pageSize();
          return _this.items().slice(start, end);
        } else {
          return _this.items();
        }
      });
      this.pageCount = ko.computed(function() {
        return Math.ceil(_this.totalCount() / _this.pageSize());
      });
      this.isFirstPage = ko.computed(function() {
        return _this.pageNumber() === 1;
      });
      this.isLastPage = ko.computed(function() {
        return _this.pageNumber() === _this.pageCount();
      });
      if (this.options.serverPaging) {
        this.pageNumber.subscribe(function() {
          return _this._doLoad();
        });
        return this.sorting.subscribe(function() {
          return _this._doLoad();
        });
      }
    };

    DataSource.prototype._doLoad = function() {
      var loadOptions;
      var _this = this;
      if ((this.options.provider != null) && _.isArray(this.options.provider)) {
        return;
      }
      if (!(this.pageNumber() != null)) return;
      loadOptions = _.extend({}, this.searchParameters());
      if (this._serverPagingEnabled) {
        loadOptions.pageSize = this.options.serverPaging;
        loadOptions.pageNumber = Math.ceil(this.pageNumber() / this.clientPagesPerServerPage);
      }
      if (this.sorting() != null) loadOptions.orderBy = this.sorting();
      if (_.isEqual(loadOptions, this._lastProviderOptions)) return;
      this.isLoading(true);
      return this.options.provider(loadOptions, (function(loadedData) {
        _this._setData(loadedData);
        _this._lastProviderOptions = loadOptions;
        return _this.isLoading(false);
      }), this);
    };

    DataSource.prototype._setData = function(loadedData) {
      var items;
      items = [];
      if (this.options.serverPaging) {
        items = loadedData.items;
        this.pageSize(this.options.clientPaging || this.options.serverPaging);
        this.totalCount(loadedData.totalCount);
      } else {
        items = loadedData;
        this.pageSize(this.options.clientPaging || loadedData.length);
        this.totalCount(loadedData.length);
      }
      if (this.options.map != null) {
        items = _(items).chain().map(this.options.map).compact().value();
      }
      this._loadedItems(items);
      return this._hasLoadedOnce = true;
    };

    return DataSource;

  })();

  bo.QueryString = (function() {

    QueryString.from = function(qs) {
      var p, query, queryKey, queryValue, split, _i, _len, _ref;
      qs = qs.replace(/&$/, '');
      qs = qs.replace(/\+/g, ' ');
      query = new QueryString();
      _ref = qs.split('&');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        split = p.split('=');
        queryKey = decodeURIComponent(split[0]);
        queryValue = decodeURIComponent(split[1]);
        query.set(queryKey, queryValue);
      }
      return query;
    };

    function QueryString() {
      this.values = {};
    }

    QueryString.prototype.set = function(key, value) {
      return this.values[key] = value;
    };

    QueryString.prototype.setAll = function(values) {
      var key, value, _results;
      _results = [];
      for (key in values) {
        if (!__hasProp.call(values, key)) continue;
        value = values[key];
        if (value != null) _results.push(this.set(key, value));
      }
      return _results;
    };

    QueryString.prototype.get = function(key) {
      return this.values[key];
    };

    QueryString.prototype.toString = function() {
      var key, params, value;
      params = (function() {
        var _ref, _results;
        _ref = this.values;
        _results = [];
        for (key in _ref) {
          value = _ref[key];
          _results.push("" + key + "=" + value);
        }
        return _results;
      }).call(this);
      if (params.length > 0) {
        return "?" + params.join("&");
      } else {
        return "";
      }
    };

    return QueryString;

  })();

  bo.query = {
    get: function(key) {
      return bo.query.current().get(key);
    },
    current: function() {
      return bo.QueryString.from(window.location.search.substring(1));
    }
  };

  bo.Command = (function() {

    function Command(name, values) {
      var key, value;
      this.name = name;
      if (values == null) values = {};
      bo.validatableModel(this);
      for (key in values) {
        value = values[key];
        this[key] = bo.utils.asObservable(value);
      }
      bo.bus.publish("commandCreated:" + this.name, this);
    }

    Command.prototype.properties = function() {
      var key, properties, value;
      properties = {};
      for (key in this) {
        value = this[key];
        if (!_(['name', 'validate', 'modelErrors', 'properties', 'modelValidationRules', 'isValid']).contains(key)) {
          properties[key] = value;
        }
      }
      return properties;
    };

    return Command;

  })();

  bo.messaging = {};

  bo.messaging.processOptions = function(options) {
    return options;
  };

  bo.messaging.config = {
    query: {
      url: "/Query/?query.name=$queryName&query.values=$queryValues"
    },
    queryDownload: {
      url: "/Query/Download?query.name=$queryName&query.values=$queryValues&contentType=$contentType"
    },
    command: {
      url: "/Command",
      batchUrl: "/Command/Batch",
      optionsParameterName: 'values'
    }
  };

  bo.messaging.query = function(queryName, options) {
    var ajaxPromise, queryOptions;
    if (options == null) options = {};
    bo.arg.ensureDefined(queryName, "queryName");
    queryOptions = bo.messaging.processOptions(options);
    ajaxPromise = jQuery.ajax({
      url: bo.messaging.config.query.url.replace("$queryValues", ko.toJSON(queryOptions)).replace("$queryName", queryName),
      type: "GET",
      dataType: "json",
      contentType: "application/json; charset=utf-8"
    });
    ajaxPromise.done(function() {
      return bo.bus.publish("queryExecuted:" + queryName, {
        name: queryName,
        options: options
      });
    });
    return ajaxPromise;
  };

  bo.messaging.queryDownload = function(queryName, contentType, options) {
    var c, form, queryOptions, url;
    if (options == null) options = {};
    bo.arg.ensureDefined(queryName, "queryName");
    bo.arg.ensureDefined(queryName, "contentType");
    queryOptions = bo.messaging.processOptions(options);
    url = bo.messaging.config.queryDownload.url.replace("$queryValues", ko.toJSON(queryOptions)).replace("$queryName", queryName).replace("$contentType", contentType);
    form = document.createElement("form");
    document.body.appendChild(form);
    form.method = "post";
    form.action = url;
    c = document.createElement("input");
    c.type = "submit";
    form.appendChild(c);
    form.submit();
    return document.body.removeChild(form);
  };

  bo.messaging.command = function(command) {
    var ajaxPromise, commandName, commandProperties;
    bo.arg.ensureDefined(command, "command");
    commandName = command.name;
    commandProperties = bo.messaging.processOptions(command.properties());
    ajaxPromise = jQuery.ajax({
      url: bo.messaging.config.command.url.replace("$commandName", commandName),
      type: "POST",
      data: ko.toJSON({
        command: {
          name: commandName,
          values: commandProperties
        }
      }),
      dataType: "json",
      contentType: "application/json; charset=utf-8"
    });
    ajaxPromise.done(function() {
      return bo.bus.publish("commandExecuted:" + commandName, {
        name: commandName,
        options: commandProperties
      });
    });
    return ajaxPromise;
  };

  bo.messaging.commands = function(commands) {
    bo.arg.ensureDefined(commands, "commands");
    return jQuery.ajax({
      url: bo.messaging.config.command.batchUrl,
      type: "POST",
      data: ko.toJSON({
        commands: ko.utils.arrayMap(commands, function(c) {
          return {
            name: c.name,
            values: c.properties()
          };
        })
      }),
      dataType: "json",
      contentType: "application/json; charset=utf-8"
    });
  };

  ko.bindingHandlers.hoverClass = {
    init: function(element, valueAccessor) {
      var $element, value;
      value = ko.utils.unwrapObservable(valueAccessor());
      $element = jQuery(element);
      return $element.hover((function() {
        return $element.addClass(value);
      }), (function() {
        return $element.removeClass(value);
      }));
    }
  };

  ko.bindingHandlers.flash = {
    update: function(element, valueAccessor) {
      var $element, value;
      $element = jQuery(element);
      value = ko.utils.unwrapObservable(valueAccessor());
      if (value != null) {
        $element.html(value).hide().slideDown(350);
        return setTimeout((function() {
          return $element.fadeOut();
        }), 3500);
      } else {
        return $element.hide();
      }
    }
  };

  ko.bindingHandlers.yesno = {
    update: function(element, valueAccessor) {
      var value;
      value = ko.utils.unwrapObservable(valueAccessor());
      return element.innerHTML = (value ? "Yes" : "No");
    }
  };

  ko.bindingHandlers.fadeVisible = {
    init: function(element, valueAccessor) {
      var value;
      value = ko.utils.unwrapObservable(valueAccessor());
      if (value) {
        return $(element).show();
      } else {
        return $(element).hide();
      }
    },
    update: function(element, valueAccessor) {
      var value;
      value = ko.utils.unwrapObservable(valueAccessor());
      if (value) {
        return $(element).fadeIn();
      } else {
        return $(element).fadeOut();
      }
    }
  };

  ko.bindingHandlers.position = {
    init: function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var $element, options, value;
      $element = jQuery(element);
      value = ko.utils.unwrapObservable(valueAccessor());
      options = {
        my: value.my || 'left top',
        at: value.at || 'right',
        of: value.of,
        offset: value.offset || '0 0',
        collision: value.collision || 'fit'
      };
      if ($element.width() === 0) {
        $element.width(ko.utils.unwrapObservable(value.width));
      }
      return $element.position(options);
    }
  };

  ko.bindingHandlers.command = {
    shouldExecute: function(enableOption, viewModel) {
      var enable;
      enable = ko.utils.unwrapObservable(enableOption);
      if (enable != null) {
        if (_.isFunction(enable)) {
          return enable.apply(viewModel);
        } else {
          return enable;
        }
      } else {
        return true;
      }
    },
    init: function(element, valueAccessor, allBindings, viewModel) {
      var commands;
      commands = valueAccessor() || {};
      if (!_.isArray(commands)) commands = [commands];
      return ko.utils.arrayForEach(commands, function(options, i) {
        var callback, doExecute, enable, eventName, keyboardShortcut, newValueAccessor;
        callback = _.isFunction(options) ? options : options.callback;
        if (callback) {
          enable = options.enable || allBindings().enable;
          eventName = options.event;
          keyboardShortcut = options.keyboard;
          doExecute = function() {
            if (ko.bindingHandlers.command.shouldExecute(enable, viewModel)) {
              return callback.apply(viewModel) || false;
            } else {
              return true;
            }
          };
          if (eventName) {
            newValueAccessor = function() {
              var result;
              result = {};
              result[eventName] = doExecute;
              return result;
            };
            ko.bindingHandlers.event.init.call(this, element, newValueAccessor, allBindings, viewModel);
          }
          if (keyboardShortcut) {
            return jQuery(element).bind('keydown', keyboardShortcut, function(event) {
              doExecute();
              event.stopPropagation();
              event.preventDefault();
              return false;
            });
          }
        }
      });
    }
  };

  currentValueBinding = ko.bindingHandlers.value;

  ko.bindingHandlers.value = {
    init: function() {
      currentValueBinding.init.apply(this, arguments);
      return ko.bindingHandlers.validated.init.apply(this, arguments);
    },
    update: function() {
      currentValueBinding.update.apply(this, arguments);
      return ko.bindingHandlers.validated.update.apply(this, arguments);
    }
  };

  ko.bindingHandlers.validated = {
    options: {
      inputValidClass: 'input-validation-valid',
      inputInvalidClass: 'input-validation-error',
      messageValidClass: 'field-validation-valid',
      messageInvalidClass: 'field-validation-error'
    },
    init: function(element, valueAccessor, allBindings, viewModel) {
      var $element, $validationElement, value, _ref;
      value = valueAccessor();
      $element = jQuery(element);
      if ((value != null ? value.errors : void 0) != null) {
        $validationElement = jQuery('<span />').insertAfter($element);
        ko.utils.domData.set(element, 'validationElement', $validationElement);
      }
      if ((value != null ? (_ref = value.validationRules) != null ? _ref.required : void 0 : void 0) != null) {
        return $element.attr("aria-required", true);
      }
    },
    update: function(element, valueAccessor, allBindings, viewModel) {
      var $element, $validationElement, errorMessages, isEnabled, isInvalid, isValid, options, shouldDisable, shouldEnable, value;
      $element = jQuery(element);
      $validationElement = ko.utils.domData.get(element, 'validationElement');
      value = valueAccessor();
      if ((value != null ? value.errors : void 0) != null) {
        shouldEnable = ko.utils.unwrapObservable(allBindings().enable || true);
        shouldDisable = ko.utils.unwrapObservable(allBindings().disable || false);
        isEnabled = shouldEnable === true && shouldDisable === false;
        errorMessages = value.errors();
        options = ko.bindingHandlers.validated.options;
        isInvalid = isEnabled && errorMessages.length > 0;
        isValid = !isInvalid;
        $element.toggleClass(options.inputValidClass, isValid);
        $element.toggleClass(options.inputInvalidClass, isInvalid);
        $element.attr("aria-invalid", isInvalid);
        $validationElement.toggleClass(options.messageValidClass, isValid);
        $validationElement.toggleClass(options.messageInvalidClass, isInvalid);
        return $validationElement.html((isValid ? '' : errorMessages.join('<br />')));
      }
    }
  };

  ko.bindingHandlers.delegatedEvent = {
    init: function(element, valueAccessor, allBindings, viewModel) {
      var eventsToHandle;
      eventsToHandle = valueAccessor() || {};
      if (!_.isArray(eventsToHandle)) eventsToHandle = [eventsToHandle];
      return ko.utils.arrayForEach(eventsToHandle, function(eventOptions) {
        var realCallback, realValueAccessor;
        realCallback = function(event) {
          var context, options;
          element = event.target;
          options = eventOptions;
          if (jQuery(element).is(options.selector)) {
            context = $(event.target).tmplItem().data;
            if (typeof options.callback === "string" && typeof context[options.callback] === "function") {
              [options.callback].call(context, event);
            } else {
              options.callback.call(viewModel, context, event);
            }
            false;
          }
          return true;
        };
        realValueAccessor = function() {
          var result;
          result = {};
          result[eventOptions.event] = realCallback;
          return result;
        };
        return ko.bindingHandlers.event.init(element, realValueAccessor, allBindings, viewModel);
      });
    }
  };

  SitemapNode = (function() {

    function SitemapNode(sitemap, name, definition) {
      var _this = this;
      this.name = name;
      this.definition = definition;
      bo.arg.ensureDefined(sitemap, "sitemap");
      bo.arg.ensureDefined(name, "name");
      bo.arg.ensureDefined(definition, "definition");
      this.parent = null;
      this.metadata = this.definition.metadata;
      this.children = ko.observableArray([]);
      this.isCurrent = ko.computed(function() {
        return sitemap.currentNode() === _this;
      });
      if (definition.url) {
        new bo.routing.Route(name, definition.url);
        bo.bus.subscribe("routeNavigated:" + name, function(data) {
          if (data == null) data = {};
          sitemap.currentNode(_this);
          return sitemap.regionManager.activate(_this.definition.parts, data.parameters);
        });
      }
      this.hasRoute = definition.url != null;
      if (definition.isInNavigation != null) {
        if (ko.isObservable(definition.isInNavigation)) {
          this.isVisible = definition.isInNavigation;
        } else {
          this.isVisible = ko.observable(definition.isInNavigation);
        }
      } else {
        this.isVisible = ko.observable(true);
      }
      this.isActive = ko.computed(function() {
        return _this.isCurrent() || _.any(_this.children(), function(c) {
          return c.isActive();
        });
      });
      this.hasChildren = ko.computed(function() {
        return _.any(_this.children(), function(c) {
          return c.isVisible();
        });
      });
    }

    SitemapNode.prototype.addChild = function(child) {
      this.children.push(child);
      return child.parent = this;
    };

    SitemapNode.prototype.getAncestorsAndThis = function() {
      var _ref;
      return (((_ref = this.parent) != null ? _ref.getAncestorsAndThis() : void 0) || []).concat([this]);
    };

    return SitemapNode;

  })();

  bo.Sitemap = (function() {

    Sitemap.knownPropertyNames = ['url', 'parts', 'isInNavigation', 'metadata'];

    function Sitemap(regionManager, pages) {
      var pageDefinition, pageName;
      var _this = this;
      this.regionManager = regionManager;
      bo.arg.ensureDefined(regionManager, "regionManager");
      bo.arg.ensureDefined(pages, "pages");
      this.currentNode = ko.observable();
      this.nodes = [];
      this.breadcrumb = ko.computed(function() {
        if (_this.currentNode() != null) {
          return _this.currentNode().getAncestorsAndThis();
        } else {
          return [];
        }
      });
      for (pageName in pages) {
        pageDefinition = pages[pageName];
        this.nodes.push(this._createNode(pageName, pageDefinition));
      }
    }

    Sitemap.prototype._createNode = function(name, definition) {
      var node, subDefinition, subName;
      node = new SitemapNode(this, name, definition);
      for (subName in definition) {
        subDefinition = definition[subName];
        if (!(_(bo.Sitemap.knownPropertyNames).contains(subName))) {
          node.addChild(this._createNode(subName, subDefinition));
        }
      }
      return node;
    };

    return Sitemap;

  })();

  Route = (function() {
    var paramRegex;

    Route.current = void 0;

    paramRegex = /{(\*?)(\w+)}/g;

    function Route(name, definition) {
      var routeDefinitionAsRegex;
      var _this = this;
      this.name = name;
      this.definition = definition;
      bo.arg.ensureString(name, 'name');
      bo.arg.ensureString(definition, 'definition');
      this.paramNames = [];
      routeDefinitionAsRegex = this.definition.replace(paramRegex, function(_, mode, name) {
        _this.paramNames.push(name);
        if (mode === '*') {
          return '(.*)';
        } else {
          return '([^/]*)';
        }
      });
      if (routeDefinitionAsRegex[0] === '/') {
        routeDefinitionAsRegex = routeDefinitionAsRegex.substring(1);
      }
      this.incomingMatcher = new RegExp("^/?" + routeDefinitionAsRegex + "/?$");
      bo.bus.subscribe("navigateToRoute:" + this.name, function(options) {
        if (options == null) options = {};
        return _this.navigateTo(options.parameters || {}, options.canVeto);
      });
      bo.bus.subscribe('urlChanged', function(data) {
        var args;
        if (Route.current !== _this) {
          if ((args = _this._match(data.url)) !== void 0) {
            return bo.bus.publish("routeNavigated:" + _this.name, {
              url: _this._create(args),
              route: _this,
              parameters: args
            });
          }
        }
      });
      bo.bus.publish("routeCreated:" + this.name, this);
    }

    Route.prototype.navigateTo = function(args, canVeto) {
      var url;
      if (args == null) args = {};
      if (canVeto == null) canVeto = true;
      url = this._create(args);
      if (Route.current !== this) {
        if ((bo.bus.publish("routeNavigating:" + this.name, {
          url: url,
          route: this,
          canVeto: canVeto
        })) || !canVeto) {
          Route.current = this;
          return bo.bus.publish("routeNavigated:" + this.name, {
            url: url,
            route: this,
            parameters: args
          });
        }
      }
    };

    Route.prototype._match = function(incoming) {
      var index, matchedParams, matches, name, _len, _ref;
      bo.arg.ensureString(incoming, 'incoming');
      matches = incoming.match(this.incomingMatcher);
      if (matches) {
        matchedParams = {};
        _ref = this.paramNames;
        for (index = 0, _len = _ref.length; index < _len; index++) {
          name = _ref[index];
          matchedParams[name] = matches[index + 1];
        }
        return matchedParams;
      }
    };

    Route.prototype._create = function(args) {
      var _this = this;
      if (args == null) args = {};
      if (this._allParametersPresent(args)) {
        return this.definition.replace(paramRegex, function(_, mode, name) {
          return args[name];
        });
      }
    };

    Route.prototype._allParametersPresent = function(args) {
      return _.all(this.paramNames, function(p) {
        return args[p] != null;
      });
    };

    Route.prototype.toString = function() {
      return "" + this.name + ": " + this.definition;
    };

    return Route;

  })();

  HistoryManager = (function() {

    function HistoryManager() {
      this.historyjs = window.History;
      this.persistedQueryParameters = {};
      this.transientQueryParameters = {};
      this.currentRouteUrl = '';
    }

    HistoryManager.prototype.setQueryParameter = function(name, value, isPersisted) {
      if (isPersisted == null) isPersisted = false;
      if (isPersisted) this.persistedQueryParameters[name] = value;
      if (!isPersisted) this.transientQueryParameters[name] = value;
      return this.historyjs.pushState(null, null, this._generateUrl(this._getNormalisedHash()));
    };

    HistoryManager.prototype.initialise = function() {
      var _this = this;
      bo.bus.subscribe('routeNavigated', function(d) {
        return _this._updateFromRouteUrl(d.url);
      });
      jQuery(window).bind('statechange', function() {
        return _this._handleExternalChange();
      });
      return this._handleExternalChange();
    };

    HistoryManager.prototype._updateFromRouteUrl = function(routeUrl) {
      this.navigating = true;
      this.currentRouteUrl = routeUrl;
      this.transientQueryParameters = {};
      this.historyjs.pushState(null, null, this._generateUrl());
      return this.navigating = false;
    };

    HistoryManager.prototype._generateUrl = function() {
      var queryString;
      queryString = new bo.QueryString();
      queryString.setAll(this.transientQueryParameters);
      queryString.setAll(this.persistedQueryParameters);
      return this.currentRouteUrl + queryString.toString();
    };

    HistoryManager.prototype._handleExternalChange = function() {
      if (!this.navigating) {
        return bo.bus.publish('urlChanged', {
          url: this._getNormalisedHash()
        });
      }
    };

    HistoryManager.prototype._getNormalisedHash = function() {
      var currentHash;
      currentHash = this.historyjs.getState().hash;
      if (currentHash.startsWith('.')) currentHash = currentHash.substring(1);
      return currentHash = currentHash.replace(bo.query.current().toString(), '');
    };

    return HistoryManager;

  })();

  bo.routing = {
    Route: Route,
    manager: new HistoryManager()
  };

  ko.bindingHandlers.navigateTo = {
    init: function(element, valueAccessor, allBindingsAccessor) {
      var parameters, routeName;
      routeName = valueAccessor();
      parameters = allBindingsAccessor().parameters || {};
      return jQuery(element).click(function(event) {
        var _ref;
        if (bo.utils.isElementEnabled(allBindingsAccessor)) {
          bo.bus.publish("navigateToRoute:" + routeName, {
            parameters: parameters,
            canVeto: (_ref = allBindingsAccessor().canVeto) != null ? _ref : true
          });
          event.preventDefault();
          return false;
        }
      });
    }
  };

  bo.Part = (function() {

    __extends(Part, bo.Bus);

    Part.region = "main";

    function Part(name, options) {
      this.name = name;
      this.options = options != null ? options : {};
      bo.arg.ensureDefined(name, 'name');
      this.title = this.options.title || name;
      this.region = this.options.region || Part.region;
      this.templateName = this.options.templateName || ("Part-" + this.name);
      if (this.options.templateName === void 0) {
        this.templatePath = this.options.templatePath || ("/Templates/Get/" + this.name);
      }
      this._isTemplateLoaded = false;
      if (_.isFunction(this.options.viewModel)) {
        this.viewModelTemplate = this.options.viewModel || {};
      } else {
        this.viewModel = this.options.viewModel || {};
      }
    }

    Part.prototype.canDeactivate = function() {
      if (this.viewModel && (this.viewModel.isDirty != null)) {
        return !(ko.utils.unwrapObservable(this.viewModel.isDirty));
      } else {
        return true;
      }
    };

    Part.prototype.deactivate = function() {};

    Part.prototype.activate = function(parameters) {
      var allPromises, loadPromises, showPromises;
      var _this = this;
      bo.arg.ensureDefined(parameters, 'parameters');
      this.publish("partActivating:" + this.name);
      this._activateViewModel();
      loadPromises = [this._loadTemplate()];
      showPromises = this._show(parameters || []);
      if (!_.isArray(showPromises)) showPromises = [showPromises];
      allPromises = _.compact(loadPromises.concat(showPromises));
      jQuery.when.apply(this, showPromises).done(function() {
        if (_this.viewModel.reset) return _this.viewModel.reset();
      });
      jQuery.when.apply(this, allPromises).done(function() {
        return _this.publish("partActivated:" + _this.name);
      });
      return allPromises;
    };

    Part.prototype._show = function(parameters) {
      bo.arg.ensureDefined(parameters, 'parameters');
      if (this.viewModel.show) return this.viewModel.show(parameters);
    };

    Part.prototype._loadTemplate = function() {
      var _this = this;
      if (!this._isTemplateLoaded && (this.templatePath != null)) {
        return jQuery.ajax({
          url: this.templatePath,
          dataType: 'html',
          type: 'GET',
          success: function(template) {
            _this._isTemplateLoaded = true;
            return bo.utils.addTemplate(_this.templateName, template);
          }
        });
      }
      return bo.utils.resolvedPromise();
    };

    Part.prototype._activateViewModel = function() {
      if (this.viewModelTemplate) {
        this.viewModel = new this.viewModelTemplate() || {};
      } else {
        this._activateViewModel = function() {};
      }
      if (this.viewModel.initialise) return this.viewModel.initialise();
    };

    return Part;

  })();

  bo.RegionManager = (function() {

    RegionManager.reactivateEvent = "reactivateParts";

    function RegionManager() {
      var _this = this;
      this.currentParts = ko.observable({});
      this.isLoading = ko.observable(false);
      bo.bus.subscribe("reactivateParts", function() {
        return _this.reactivate();
      });
    }

    RegionManager.prototype.reactivate = function() {
      return this.activate(_.values(this.currentParts(), this.currentParameters));
    };

    RegionManager.prototype.canDeactivate = function(options) {
      var hasDirtyPart;
      if (options == null) options = {};
      hasDirtyPart = _.any(this.currentParts(), function(part) {
        return !part.canDeactivate();
      });
      if (hasDirtyPart > 0) {
        if (options.showConfirmation === false) {
          return false;
        } else {
          return window.confirm("Do you wish to lose your changes?");
        }
      } else {
        return true;
      }
    };

    RegionManager.prototype.activate = function(parts, parameters) {
      var currentPartsToSet, part, partPromises, _i, _len;
      var _this = this;
      if (parameters == null) parameters = {};
      if (this.canDeactivate()) {
        bo.bus.publish("partsActivating", {
          parts: parts
        });
        this.isLoading(true);
        this._deactivateAll();
        partPromises = [];
        currentPartsToSet = {};
        for (_i = 0, _len = parts.length; _i < _len; _i++) {
          part = parts[_i];
          partPromises = partPromises.concat(part.activate(parameters));
          currentPartsToSet[part.region] = part;
        }
        return jQuery.when.apply(this, partPromises).done(function() {
          _this.currentParts(currentPartsToSet);
          _this.currentParameters = parameters;
          _this.isLoading(false);
          return bo.bus.publish("partsActivated", {
            parts: parts
          });
        });
      }
    };

    RegionManager.prototype._deactivateAll = function() {
      var part, region, _ref, _results;
      _ref = this.currentParts();
      _results = [];
      for (region in _ref) {
        part = _ref[region];
        _results.push(part.deactivate());
      }
      return _results;
    };

    return RegionManager;

  })();

  currentPartsValueAccessor = function(regionManager) {
    return function() {
      return {
        'ifnot': _.isEmpty(regionManager.currentParts()),
        'templateEngine': ko.nativeTemplateEngine.instance,
        'data': regionManager
      };
    };
  };

  ko.bindingHandlers.regionManager = {
    init: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
      var regionManager;
      regionManager = ko.utils.unwrapObservable(valueAccessor());
      valueAccessor = currentPartsValueAccessor(regionManager);
      ko.bindingHandlers.template.init(element, valueAccessor, allBindingsAccessor, regionManager, bindingContext);
      return regionManager.isLoading.subscribe(function(isLoading) {
        return ko.utils.toggleDomNodeCssClass(element, 'is-loading', isLoading);
      });
    },
    update: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
      var regionManager;
      regionManager = ko.utils.unwrapObservable(valueAccessor());
      valueAccessor = currentPartsValueAccessor(regionManager);
      return ko.bindingHandlers.template.update(element, valueAccessor, allBindingsAccessor, regionManager, bindingContext);
    }
  };

  ko.bindingHandlers.region = {
    init: function(element, valueAccessor, allBindingsAccessor, viewModel) {
      if (!(viewModel instanceof bo.RegionManager)) {
        throw 'A region binding must be enclosed within a regionManager binding.';
      }
      return {
        "controlsDescendantBindings": true
      };
    },
    update: function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var part, region, regionManager;
      region = valueAccessor();
      regionManager = viewModel;
      part = regionManager.currentParts()[region];
      if (part != null) {
        return ko.renderTemplate(part.templateName, part.viewModel, {}, element, "replaceChildren");
      } else {
        return ko.removeNode(element);
      }
    }
  };

  bo.ViewModel = (function() {

    function ViewModel() {
      var _this = this;
      this._toValidate = ko.observableArray();
      this.isDirty = ko.observable(false);
      if (this.getCommandsToSubmit != null) {
        this.commandsToSubmit = ko.computed({
          read: this.getCommandsToSubmit.bind(this),
          deferEvaluation: true
        });
      } else {
        this.commandsToSubmit = ko.observable([]);
      }
      this.canSubmit = ko.computed({
        read: function() {
          return _this.isDirty() && _this.commandsToSubmit().length > 0;
        },
        deferEvaluation: true
      });
    }

    ViewModel.prototype.reset = function() {
      return this.isDirty(false);
    };

    ViewModel.prototype.set = function(propertyName, value) {
      var newObs;
      if (this[propertyName]) {
        this[propertyName](value);
      } else {
        newObs = bo.utils.asObservable(value);
        this[propertyName] = newObs;
        this._toValidate.push(newObs);
        this.registerForDirtyTracking(newObs);
      }
      return this[propertyName];
    };

    ViewModel.prototype.setAll = function(properties) {
      var propertyName, value, _results;
      _results = [];
      for (propertyName in properties) {
        value = properties[propertyName];
        _results.push(this.set(propertyName, value));
      }
      return _results;
    };

    ViewModel.prototype.registerForDirtyTracking = function(o) {
      var key, propValue, value, _results;
      var _this = this;
      if ((o != null ? o.subscribe : void 0) != null) {
        o.subscribe(function(newValue) {
          return _this.isDirty(true);
        });
      }
      propValue = ko.utils.unwrapObservable(o);
      if ((jQuery.type(propValue)) === 'object') {
        _results = [];
        for (key in propValue) {
          value = propValue[key];
          _results.push(this.registerForDirtyTracking(value));
        }
        return _results;
      }
    };

    ViewModel.prototype.validate = function() {
      var obj, unwrapped, _i, _len, _ref, _results;
      _ref = this._toValidate();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        obj = _ref[_i];
        unwrapped = ko.utils.unwrapObservable(obj);
        if ((unwrapped != null ? unwrapped.validate : void 0) != null) {
          _results.push(unwrapped.validate());
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    ViewModel.prototype.submit = function() {
      var ajaxPromise;
      var _this = this;
      this.validate();
      if (this._areCommandsToSubmitValid() && this.canSubmit()) {
        if (this.commandsToSubmit().length === 1) {
          ajaxPromise = bo.messaging.command(this.commandsToSubmit()[0]);
        } else {
          ajaxPromise = bo.messaging.commands(this.commandsToSubmit());
        }
        return ajaxPromise.done(function() {
          _this.reset();
          if (_this.onSubmitSuccess != null) return _this.onSubmitSuccess();
        });
      }
    };

    ViewModel.prototype._areCommandsToSubmitValid = function() {
      return _.all(this.commandsToSubmit(), function(c) {
        return c.isValid();
      });
    };

    return ViewModel;

  })();

  bo.ViewModel.subclass = function(constructorFunc) {
    var viewModel;
    viewModel = (function() {

      __extends(viewModel, bo.ViewModel);

      function viewModel() {
        viewModel.__super__.constructor.call(this);
        if (constructorFunc) constructorFunc.apply(this, arguments);
      }

      return viewModel;

    })();
    return viewModel;
  };

  bo.utils.addTemplate('breadcrumbTemplate', '<ul class="bo-breadcrumb" data-bind="foreach: breadcrumb">\n    <li>\n        <!-- ko ifnot: hasRoute -->\n            <span class="current" data-bind="text: name"></span>\n        <!-- /ko -->\n\n        <!-- ko if: hasRoute -->\n            <a href="#" data-bind="navigateTo: name, text: name"></a>\n        <!-- /ko -->\n    </li>\n</ul>');

  ko.bindingHandlers.breadcrumb = {
    'init': function(element, valueAccessor) {
      var sitemap;
      sitemap = ko.utils.unwrapObservable(valueAccessor());
      if (sitemap) {
        ko.renderTemplate("breadcrumbTemplate", sitemap, {}, element, "replaceNode");
      }
      return {
        "controlsDescendantBindings": true
      };
    }
  };

  ko.bindingHandlers.button = {
    init: function(element, valueAccessor) {
      var $element, value;
      value = ko.utils.unwrapObservable(valueAccessor());
      $element = jQuery(element);
      jQuery("<span></span>").html($element.text()).appendTo($element.empty());
      if (_.isFunction(value)) {
        return ko.bindingHandlers.click.init.apply(this, arguments);
      }
    }
  };

  ko.bindingHandlers.columnSort = {
    init: function(element, viewModelAccessor) {
      var dataSource, property;
      dataSource = viewModelAccessor().dataSource;
      property = viewModelAccessor().property;
      ko.utils.toggleDomNodeCssClass(element, 'sortable', true);
      return ko.utils.registerEventHandler(element, 'click', function() {
        var sortOrder;
        sortOrder = (dataSource.getPropertySortOrder(property)) || 'descending';
        if (sortOrder === 'descending') {
          return dataSource.sortBy("" + property + " ascending");
        } else {
          return dataSource.sortBy("" + property + " descending");
        }
      });
    },
    update: function(element, viewModelAccessor) {
      var dataSource, property, sortOrder;
      dataSource = viewModelAccessor().dataSource;
      property = viewModelAccessor().property;
      sortOrder = dataSource.getPropertySortOrder(property);
      ko.utils.toggleDomNodeCssClass(element, 'ascending', sortOrder === 'ascending');
      return ko.utils.toggleDomNodeCssClass(element, 'descending', sortOrder === 'descending');
    }
  };

  MenuItem = (function() {

    function MenuItem(data, container) {
      var _ref;
      this.data = data;
      this.container = container;
      this.dataItem = {};
      this.text = ko.observable(this.data.text || '');
      this.iconCssClass = ko.observable(this.data.iconCssClass || '');
      this.separator = ko.observable(this.data.separator === true);
      this.disabled = ko.observable(this.data.disabled === false);
      this.run = _.isFunction(this.data.run) ? this.data.run : eval(this.data.run);
      if (((_ref = this.data.items) != null ? _ref.length : void 0) > 0) {
        this.subMenu = new Menu({
          items: this.data.items
        }, this.container);
      }
    }

    MenuItem.prototype.hasChildren = function() {
      return this.subMenu != null;
    };

    MenuItem.prototype.setDataItem = function(dataItem) {
      var subMenuItem, _i, _len, _ref, _results;
      this.dataItem = dataItem;
      if (this.hasChildren()) {
        _ref = this.subMenu.items();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          subMenuItem = _ref[_i];
          _results.push(subMenuItem.setDataItem(dataItem));
        }
        return _results;
      }
    };

    MenuItem.prototype.execute = function() {
      if (this.disabled() || !this.run) false;
      return this.run(this.dataItem);
    };

    return MenuItem;

  })();

  Menu = (function() {

    function Menu(data, viewModel) {
      var i;
      this.data = data;
      this.viewModel = viewModel;
      this.cssClass = ko.observable(this.data.cssClass || this.viewModel.cssClass);
      this.name = ko.observable(this.data.name);
      this.items = ko.observableArray((function() {
        var _i, _len, _ref, _results;
        _ref = this.data.items;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          _results.push(new MenuItem(i, this));
        }
        return _results;
      }).call(this));
    }

    return Menu;

  })();

  bo.ui.ContextMenu = (function() {

    function ContextMenu(configuration) {
      var menu;
      this.cssClass = ko.observable(configuration.cssClass || 'ui-context');
      this.build = _.isFunction(configuration.build) ? configuration.build : eval(configuration.build);
      this.contextMenus = ko.observableArray((function() {
        var _i, _len, _ref, _results;
        _ref = configuration.contextMenus;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          menu = _ref[_i];
          _results.push(new Menu(menu, this));
        }
        return _results;
      }).call(this));
    }

    return ContextMenu;

  })();

  bo.utils.addTemplate('contextItemTemplate', '<li data-bind="click: execute, bubble: false, css: { separator : separator, disabled : disabled }">\n    <!-- ko ifnot: separator -->\n        <a href=#" data-bind="css: { parent : hasChildren() }">\n            <!-- Add Image Here? -->\n            <span data-bind="text: text" />\n        </a>\n    <!-- /ko -->\n\n    <!-- ko if: hasChildren() -->\n        <div style="position:absolute;">\n            <ul data-bind=\'template: { name: "contextItemTemplate", foreach: subMenu.items }\'></ul>\n        </div>\n    <!-- /ko -->\n</li>');

  bo.utils.addTemplate('contextMenuTemplate', '<div class="ui-context" style="position:absolute;" data-bind="position: { of: mousePosition }">\n    <div class="gutterLine"></div>\n    <ul data-bind=\'template: { name: "contextItemTemplate", foreach: menu.items }\'></ul>\n</div>');

  ko.bindingHandlers.contextMenu = {
    'init': function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var $element, builder, parentVM, showContextMenu, value;
      value = ko.utils.unwrapObservable(valueAccessor());
      if (!value) return;
      $element = jQuery(element);
      parentVM = viewModel;
      builder = value.build;
      showContextMenu = function(evt) {
        var config, menu, menuContainer, menuItem, _i, _len, _ref;
        config = value.build(evt, parentVM);
        if (!(config != null)) return;
        menu = value.contextMenus().filter(function(x) {
          return x.name() === config.name;
        })[0];
        if ((menu != null)) {
          jQuery('.ui-context').remove();
          config.menu = menu;
          config.mousePosition = evt;
          menuContainer = jQuery('<div></div>').appendTo('body');
          _ref = config.menu.items();
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            menuItem = _ref[_i];
            menuItem.setDataItem(parentVM);
          }
          ko.renderTemplate("contextMenuTemplate", config, {}, menuContainer, "replaceNode");
          return true;
        } else {
          return false;
        }
      };
      $element.mousedown(function(evt) {
        if (evt.which === 3) return !(showContextMenu(evt));
      });
      $element.bind('contextmenu', function(evt) {
        return !(showContextMenu(evt));
      });
      jQuery('.ui-context').live('contextmenu', function() {
        return false;
      });
      jQuery(document).bind('keydown', 'esc', function() {
        return jQuery('.ui-context').remove();
      });
      return jQuery('html').click(function() {
        return jQuery('.ui-context').remove();
      });
    }
  };

  ko.bindingHandlers.subContext = {
    'init': function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var $element, cssClass, value, width;
      $element = jQuery(element);
      value = ko.utils.unwrapObservable(valueAccessor());
      width = ko.utils.unwrapObservable(viewModel.width());
      if (value) {
        cssClass = '.' + viewModel.container.cssClass();
        jQuery(cssClass, $element).hide();
        return $element.hover(function() {
          var $parent;
          $parent = jQuery(this);
          return jQuery(cssClass, $parent).first().toggle().position({
            my: 'left top',
            at: 'right top',
            of: $parent,
            collision: 'flip'
          });
        });
      }
    }
  };

  ko.bindingHandlers.datepicker = {
    init: function(element) {
      return jQuery(element).datepicker({
        dateFormat: 'yy/mm/dd'
      });
    }
  };

  draggableModel = {
    currentlyDragging: ko.observable(),
    canDrop: ko.observable(),
    dropTarget: ko.observable()
  };

  ko.bindingHandlers.draggable = {
    init: function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var $element, dragOptions, value, _ref;
      $element = jQuery(element);
      value = ko.utils.unwrapObservable(valueAccessor());
      if (value === false || ((_ref = value.enabled) != null ? _ref : true) === false) {
        return;
      }
      if (value.template) {
        value.helper = function() {
          var helper;
          helper = jQuery('<div id="custom-draggable-helper" />');
          _.defer(function() {
            return ko.renderTemplate(value.template, draggableModel, {}, helper[0], "replaceChildren");
          });
          return helper;
        };
      }
      dragOptions = {
        revert: 'invalid',
        revertDuration: 250,
        appendTo: 'body',
        helper: 'clone',
        zIndex: 200000,
        distance: 10,
        start: function(e, ui) {
          draggableModel.canDrop(false);
          draggableModel.dropTarget(void 0);
          draggableModel.currentlyDragging(viewModel);
          return $element.attr("aria-grabbed", true);
        },
        stop: function() {
          $element.attr("aria-grabbed", false);
          return _.defer(function() {
            return draggableModel.currentlyDragging(void 0);
          });
        }
      };
      $element.draggable(jQuery.extend({}, dragOptions, value));
      return $element.attr("aria-grabbed", false);
    },
    update: function() {
      return jQuery("body").toggleClass("ui-drag-in-progress", draggableModel.currentlyDragging() != null);
    }
  };

  ko.bindingHandlers.dropTarget = {
    init: function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var $element, canAccept, dropOptions, handler, value;
      $element = jQuery(element);
      value = valueAccessor() || {};
      canAccept = ko.utils.unwrapObservable(value.canAccept);
      handler = ko.utils.unwrapObservable(value.onDropComplete);
      dropOptions = {
        greedy: true,
        tolerance: 'pointer',
        hoverClass: 'ui-hovered-drop-target',
        accept: function() {
          if (draggableModel.currentlyDragging() != null) {
            return canAccept.call(viewModel, draggableModel.currentlyDragging());
          } else {
            return false;
          }
        },
        over: function() {
          var canAcceptDrop;
          canAcceptDrop = canAccept.call(viewModel, draggableModel.currentlyDragging());
          draggableModel.canDrop(canAcceptDrop);
          return draggableModel.dropTarget(viewModel);
        },
        out: function() {
          draggableModel.canDrop(false);
          return draggableModel.dropTarget(void 0);
        },
        drop: function() {
          return _.defer(function() {
            return handler.call(viewModel, draggableModel.currentlyDragging());
          });
        }
      };
      return $element.droppable(jQuery.extend({}, dropOptions, value));
    },
    update: function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var $element, canAccept, dropEffect, value;
      $element = jQuery(element);
      value = valueAccessor() || {};
      canAccept = ko.utils.unwrapObservable(value.canAccept);
      dropEffect = ko.utils.unwrapObservable(value.dropEffect || "move");
      if (draggableModel.currentlyDragging() != null) {
        canAccept = canAccept.call(viewModel, draggableModel.currentlyDragging());
        $element.toggleClass("ui-valid-drop-target", canAccept);
        $element.toggleClass("ui-invalid-drop-target", !canAccept);
        if (canAccept) {
          return $element.attr("aria-dropeffect", dropEffect);
        } else {
          return $element.attr("aria-dropeffect", "none");
        }
      } else {
        $element.removeClass("ui-valid-drop-target");
        return $element.removeClass("ui-invalid-drop-target");
      }
    }
  };

  ko.bindingHandlers.indeterminateCheckbox = {
    init: function(element, valueAccessor) {
      var $element;
      $element = jQuery(element);
      return $element.click(function() {
        if ((ko.utils.unwrapObservable(valueAccessor())) === "mixed") {
          return valueAccessor()(true);
        } else {
          return valueAccessor()($element.is(":checked"));
        }
      });
    },
    update: function(element, valueAccessor) {
      var originalInput, value;
      value = ko.utils.unwrapObservable(valueAccessor());
      originalInput = jQuery(element);
      if (value === "mixed") {
        return originalInput.prop("indeterminate", true);
      } else {
        originalInput.prop("indeterminate", false);
        return originalInput.prop("checked", value);
      }
    }
  };

  currentEnableBindingUpdate = ko.bindingHandlers.enable.update;

  ko.bindingHandlers.enable.update = function(element, valueAccessor) {
    var isEnabled;
    currentEnableBindingUpdate(element, valueAccessor);
    isEnabled = ko.utils.unwrapObservable(valueAccessor());
    ko.utils.toggleDomNodeCssClass(element, 'disabled', !isEnabled);
    return element.setAttribute('aria-disabled', isEnabled ? 'false' : 'true');
  };

  ko.bindingHandlers.indeterminateCheckbox = {
    init: function(element, valueAccessor) {
      var $element;
      $element = jQuery(element);
      return $element.click(function() {
        if ((ko.utils.unwrapObservable(valueAccessor())) === "mixed") {
          return valueAccessor()(true);
        } else {
          return valueAccessor()($element.is(":checked"));
        }
      });
    },
    update: function(element, valueAccessor) {
      var originalInput, value;
      value = ko.utils.unwrapObservable(valueAccessor());
      originalInput = jQuery(element);
      if (value === "mixed") {
        return originalInput.prop("indeterminate", true);
      } else {
        originalInput.prop("indeterminate", false);
        return originalInput.prop("checked", value);
      }
    }
  };

  bo.utils.addTemplate('navigationItem', '<li data-bind="css: { active: isActive, current: isCurrent, \'has-children\': hasChildren }, visible: isVisible">\n    <!-- ko if: hasRoute -->\n        <a class="name" href="#" data-bind="navigateTo: name, text: name"></a>\n        <span class="after-link"></span>\n    <!-- /ko -->\n    <!-- ko ifnot: hasRoute -->\n        <span class="name" data-bind="text: name"></span>\n    <!-- /ko -->\n    <ul class="bo-navigation-sub-item" data-bind="template: { name : \'navigationItem\', foreach: children }"></ul>\n</li>');

  bo.utils.addTemplate('navigationTemplate', '<ul class="bo-navigation" data-bind="template: { name : \'navigationItem\', foreach: nodes }"></ul>');

  ko.bindingHandlers.navigation = {
    init: function(element, valueAccessor) {
      var sitemap;
      sitemap = ko.utils.unwrapObservable(valueAccessor());
      if (sitemap) {
        ko.renderTemplate("navigationTemplate", sitemap, {}, element, "replaceChildren");
      }
      return {
        "controlsDescendantBindings": true
      };
    }
  };

  bo.utils.addTemplate('printItemTemplate', '<tr>\n    <td style="padding: 2px 4px 0 0; color: #000"><span data-bind="text: key" />:</td>\n    <td style="padding: 0 0 0 4px" data-bind="output: value" />\n</tr>');

  bo.utils.addTemplate('objectTemplate', '<table class="bo-pretty-print">\n    <tbody data-bind="template: { name : \'printItemTemplate\', foreach: properties }" />\n</table>');

  getType = function(v) {
    var oType;
    if (v === null) return "null";
    if (v === void 0) return "undefined";
    if (v.nodeType && v.nodeType === 1) return "domelement";
    if (v.nodeType) return "domnode";
    oType = Object.prototype.toString.call(v).match(/\s(.+?)\]/)[1].toLowerCase();
    if (/^(string|number|array|regexp|function|date|boolean)$/.test(oType)) {
      return oType;
    }
    if (v.jquery) return "jquery";
    return "object";
  };

  simpleHandler = function(element, value, color) {
    if (color == null) color = '#000';
    return jQuery(element).html("<span style='color: " + color + "'>" + value + "</span>");
  };

  handlers = {
    array: function(element, value) {
      var propKey, propValue, properties;
      if (value.length === 0) {
        return simpleHandler(element, '[]');
      } else {
        properties = [];
        for (propKey in value) {
          if (!__hasProp.call(value, propKey)) continue;
          propValue = value[propKey];
          properties.push({
            key: "[" + propKey + "]",
            value: ko.utils.unwrapObservable(propValue)
          });
        }
        return ko.renderTemplate("objectTemplate", {
          properties: properties
        }, {}, element, "replaceChildren");
      }
    },
    object: function(element, value) {
      var propKey, propValue, properties;
      if (jQuery.isEmptyObject(value)) {
        return simpleHandler(element, '{}');
      } else {
        properties = [];
        for (propKey in value) {
          if (!__hasProp.call(value, propKey)) continue;
          propValue = value[propKey];
          properties.push({
            key: propKey,
            value: ko.utils.unwrapObservable(propValue)
          });
        }
        return ko.renderTemplate("objectTemplate", {
          properties: properties
        }, {}, element, "replaceChildren");
      }
    },
    string: function(element, value) {
      return simpleHandler(element, '"' + value + '"', '#080');
    },
    number: function(element, value) {
      return simpleHandler(element, value);
    },
    regexp: function(element, value) {
      return simpleHandler(element, value.toString(), '#080');
    },
    "function": function(element, value) {
      return simpleHandler(element, "[function]");
    },
    date: function(element, value) {
      return simpleHandler(element, value);
    },
    boolean: function(element, value) {
      return simpleHandler(element, value, '#008');
    },
    domelement: function(element, value) {
      var id;
      id = value.id || '[none]';
      return simpleHandler(element, "DOM Element: &lt;" + (value.nodeName.toLowerCase()) + " id='" + id + "' /&gt;");
    },
    domnode: function(element, value) {
      return simpleHandler(element, "DOM Node of type " + value.nodeType);
    },
    "null": function(element, value) {
      return simpleHandler(element, 'null', '#008');
    },
    undefined: function(element, value) {
      return simpleHandler(element, 'undefined', '#008');
    },
    jquery: function(element, value) {
      return simpleHandler(element, "jQuery(<span style='color: #080'>'" + value.selector + "'</span>)");
    }
  };

  ko.bindingHandlers.output = {
    init: function() {
      return {
        "controlsDescendantBindings": true
      };
    },
    update: function(element, valueAccessor) {
      var value;
      value = ko.utils.unwrapObservable(valueAccessor());
      return handlers[getType(value)](element, value);
    }
  };

  bo.utils.addTemplate('pagerPageLinkTemplate', '<li data-bind="text: pageNumber, click: select, css: { \'is-selected\': isSelected, \'page\': true }"></li>');

  bo.utils.addTemplate('pagerTemplate', '<div class="pager">\n    <ol class="previousLinks">\n    <li class="goto-first" data-bind="click: goToFirstPage, enable: !isFirstPage()">First</li>\n    <li class="goto-previous" data-bind="click: goToPreviousPage, enable: !isFirstPage()">Previous</li>\n</ol>\n\n    <ol class="pageLinks" data-bind="template: { foreach: pages, name: \'pagerPageLinkTemplate\' }"></ol>\n\n    <ol class="nextLinks">\n    <li class="goto-next" data-bind="enable: !isLastPage(), click: goToNextPage">Next</li>\n    <li class="goto-last" data-bind="enable: !isLastPage(), click: goToLastPage">Last</li>\n</ol>\n   </div>');

  PagerModel = (function() {

    function PagerModel(dataSource, maximumPagesShown) {
      var _this = this;
      this.dataSource = dataSource;
      this.isFirstPage = this.dataSource.isFirstPage;
      this.isLastPage = this.dataSource.isLastPage;
      this.goToFirstPage = function() {
        return this.dataSource.goToFirstPage();
      };
      this.goToPreviousPage = function() {
        return this.dataSource.goToPreviousPage();
      };
      this.goToNextPage = function() {
        return this.dataSource.goToNextPage();
      };
      this.goToLastPage = function() {
        return this.dataSource.goToLastPage();
      };
      this.pages = ko.computed(function() {
        var endPage, pages, startPage;
        if (_this.dataSource.pageCount() > 0) {
          startPage = _this.dataSource.pageNumber() - (maximumPagesShown / 2);
          startPage = Math.max(1, Math.min(dataSource.pageCount() - maximumPagesShown + 1, startPage));
          endPage = startPage + maximumPagesShown;
          endPage = Math.min(endPage, _this.dataSource.pageCount() + 1);
          pages = _.range(startPage, endPage);
          return _(pages).map(function(p) {
            return {
              pageNumber: p,
              isSelected: p === _this.dataSource.pageNumber(),
              select: function() {
                return _this.dataSource.pageNumber(p);
              }
            };
          });
        } else {
          return [];
        }
      });
    }

    return PagerModel;

  })();

  ko.bindingHandlers.pager = {
    init: function(element, valueAccessor, allBindingsAccessor) {
      var dataSource, maximumPagesShown, _ref;
      dataSource = valueAccessor();
      maximumPagesShown = (_ref = allBindingsAccessor().maximumPagesShown) != null ? _ref : 10;
      if (dataSource.pagingEnabled === true) {
        ko.renderTemplate('pagerTemplate', new PagerModel(dataSource, maximumPagesShown), {}, element, 'replaceChildren');
        return {
          "controlsDescendantBindings": true
        };
      }
    }
  };

  ko.bindingHandlers.splitter = {
    init: function(element, valueAccessor) {
      var $left, $parent, $right, $splitter, enabled, leftMaxWidth, leftMinWidth, leftXBorderWidth, parentLeftBorder, parentOffset, parentWidth, rightMaxWidth, rightMinWidth, rightXBorderWidth, sliderLeftWall, sliderRightWall, splitterOuterWidth, splitterPosition, value;
      value = valueAccessor();
      enabled = value.enabled;
      $splitter = jQuery(element);
      $parent = $splitter.parent();
      $left = $splitter.prev();
      $right = $splitter.next();
      if (!$left.is(':visible') || !$right.is(':visible')) return;
      $splitter.addClass('splitter');
      parentWidth = $parent.width();
      splitterOuterWidth = $splitter.outerWidth();
      rightXBorderWidth = $right.outerWidth() - $right.width();
      leftXBorderWidth = $left.outerWidth() - $left.width();
      leftMinWidth = parseInt($left.css('min-width'), 10);
      rightMinWidth = parseInt($right.css('min-width'), 10);
      leftMaxWidth = $parent.width() - (rightMinWidth + rightXBorderWidth + leftXBorderWidth + splitterOuterWidth);
      rightMaxWidth = $parent.width() - (leftMinWidth + leftXBorderWidth + rightXBorderWidth + splitterOuterWidth);
      $left.css({
        left: 0,
        top: 0,
        bottom: 0,
        position: 'absolute'
      });
      $right.css({
        right: 0,
        top: 0,
        bottom: 0,
        position: 'absolute'
      });
      splitterPosition = ko.observable($left.outerWidth());
      ko.computed(function() {
        var desiredLeftWidth, desiredRightWidth;
        desiredLeftWidth = splitterPosition() - leftXBorderWidth;
        desiredRightWidth = parentWidth - splitterPosition() - splitterOuterWidth - rightXBorderWidth;
        $left.css('width', Math.min(leftMaxWidth, Math.max(leftMinWidth, desiredLeftWidth)));
        $right.css('width', Math.min(rightMaxWidth, Math.max(rightMinWidth, desiredRightWidth)));
        return $splitter.css('left', Math.min(leftMaxWidth + leftXBorderWidth, Math.max(leftMinWidth + leftXBorderWidth, splitterPosition())));
      });
      parentLeftBorder = parseInt($parent.css('border-left-width'), 10);
      parentOffset = $parent.offset();
      sliderLeftWall = parentOffset.left + leftMinWidth + leftXBorderWidth + parentLeftBorder;
      sliderRightWall = parentOffset.left + parentWidth - rightXBorderWidth - parentLeftBorder - rightMinWidth - splitterOuterWidth;
      return $splitter.draggable({
        axis: "x",
        containment: [sliderLeftWall, 0, sliderRightWall, 0],
        drag: function(event, ui) {
          return splitterPosition(ui.position.left);
        }
      });
    }
  };

  window.bo.ui = window.bo.ui || {};

  TreeNode = (function() {

    function TreeNode(data, parent, viewModel) {
      var o, _i, _len, _ref, _ref2;
      var _this = this;
      this.data = data;
      this.viewModel = viewModel;
      this.isTreeNode = true;
      this.parent = ko.observable(parent);
      this.id = this.data.id;
      this.name = ko.observable(this.data.name);
      this.isRoot = !(parent != null);
      this.contextMenu = this.viewModel.contextMenu;
      this.type = this.data.type || 'folder';
      this.cssClass = this.data.cssClass || this.type.toLowerCase();
      this.checkState = ko.observable(this.data.isChecked || false);
      this.checkState.subscribe(function(newValue) {
        if (newValue === true) {
          _this.viewModel.checkedNodes.push(_this);
        } else {
          _this.viewModel.checkedNodes.remove(_this);
        }
        if (!_this.isRoot) return _this.parent()._updateCheckState();
      });
      if (parent != null) {
        parent.checkState.subscribe(function(newValue) {
          if (newValue !== "mixed") return _this.checkState(newValue);
        });
      }
      if (parent) this.checkState(this.parent().checkState());
      this.isOpen = ko.observable((_ref = this.data.isOpen) != null ? _ref : false);
      this.isSelected = ko.observable(false);
      this.isFocused = ko.observable(false);
      this.isRenaming = ko.observable(false);
      this.editingName = ko.observable();
      this.isRenaming.subscribe(function(newValue) {
        if (newValue) return _this.editingName(_this.name());
      });
      this.children = ko.observableArray([]).extend({
        onDemand: function() {
          if (_this.data.loadChildren) {
            return _this.data.loadChildren(function(loadedChildren) {
              return _this.setChildren(loadedChildren);
            });
          }
        }
      });
      this.isLeaf = ko.computed(function() {
        return _this.children.loaded() && _this.children().length === 0 && !_this.isRoot;
      });
      this.level = ko.computed(function() {
        if (_this.isRoot) {
          return 0;
        } else {
          return _this.parent().level() + 1;
        }
      });
      this.indent = ko.computed(function() {
        return (_this.level() * 11) + 'px';
      });
      _ref2 = ["isDraggable", "isDropTarget", "canAddChildren", "childType", "renameAfterAdd", "canRename", "canDelete", "defaultChildName"];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        o = _ref2[_i];
        this._setOption(o);
      }
      if (!this.data.loadChildren) this.setChildren(this.data.children || []);
      if (this.isOpen()) this.children.load();
    }

    TreeNode.prototype.getFullPath = function(includeRoot) {
      var isLastNode, parentName;
      isLastNode = this.parent() === null || (this.parent().isRoot && !includeRoot);
      if (isLastNode) {
        return this.name();
      } else {
        parentName = (!isLastNode ? this.parent().getFullPath(includeRoot) : '');
        return "" + parentName + "/" + (this.name());
      }
    };

    TreeNode.prototype.setChildren = function(childrenToConvert) {
      var n;
      return this.children((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = childrenToConvert.length; _i < _len; _i++) {
          n = childrenToConvert[_i];
          _results.push(this._createChild(n));
        }
        return _results;
      }).call(this));
    };

    TreeNode.prototype.select = function() {
      if (this.viewModel.selectedNode() != null) {
        this.viewModel.selectedNode().isSelected(false);
      }
      this.isSelected(true);
      this.viewModel.selectedNode(this);
      return this.focus();
    };

    TreeNode.prototype.toggleFolder = function() {
      var _this = this;
      return this.children.load(function() {
        return _this.isOpen(!_this.isOpen());
      });
    };

    TreeNode.prototype.beginRenaming = function() {
      if (this.canRename) return this.isRenaming(true);
    };

    TreeNode.prototype.cancelRenaming = function() {
      this.isRenaming(false);
      return this.focus();
    };

    TreeNode.prototype.commitRenaming = function() {
      var _this = this;
      if (this.isRenaming()) {
        this.isRenaming(false);
        if (this.name() !== this.editingName()) {
          this._executeHandler('onRename', this.name(), this.editingName(), function() {
            return _this.name(_this.editingName());
          });
        }
      }
      return this.focus();
    };

    TreeNode.prototype.canAcceptDrop = function(e) {
      var _this = this;
      return this._executeHandler('canAcceptDrop', e, function(droppable) {
        return (droppable instanceof TreeNode) && _this.isDropTarget && droppable !== _this && _this !== droppable.parent() && !_this.isDescendantOf(droppable);
      });
    };

    TreeNode.prototype.acceptDrop = function(droppable) {
      if (droppable instanceof TreeNode) {
        return droppable.moveTo(this);
      } else {
        return this._executeHandler('onAcceptUnknownDrop', droppable);
      }
    };

    TreeNode.prototype.isDescendantOf = function(parent) {
      return !this.isRoot && (this.parent() === parent || this.parent().isDescendantOf(parent));
    };

    TreeNode.prototype.moveTo = function(newParent) {
      var _this = this;
      return this._executeHandler("onMove", newParent, function() {
        _this.parent().children.remove(_this);
        _this.parent(newParent);
        return newParent.children.load(function() {
          newParent.children.push(_this);
          newParent.isOpen(true);
          return _this.select();
        });
      });
    };

    TreeNode.prototype.deleteSelf = function() {
      var _this = this;
      if (this.canDelete) {
        return this._executeHandler('onDelete', function() {
          var child, _i, _len, _ref;
          _ref = _this.children();
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            child = _ref[_i];
            child.deleteSelf();
          }
          _this.parent().children.remove(_this);
          return _this.parent().select();
        });
      }
    };

    TreeNode.prototype.open = function() {
      var _this = this;
      return this.children.load(function() {
        return _this.isOpen(true);
      });
    };

    TreeNode.prototype.close = function() {
      return this.isOpen(false);
    };

    TreeNode.prototype.previousSibling = function() {
      var nodeIndex;
      if (this.isRoot) {
        return null;
      } else {
        nodeIndex = this.parent().children.indexOf(this);
        if (nodeIndex === 0) {
          return null;
        } else {
          return this.parent().children()[nodeIndex - 1];
        }
      }
    };

    TreeNode.prototype.nextSibling = function() {
      var nodeIndex;
      if (this.isRoot) {
        return null;
      } else {
        nodeIndex = this.parent().children.indexOf(this);
        if (nodeIndex === this.parent().children().length - 1) {
          return null;
        } else {
          return this.parent().children()[nodeIndex + 1];
        }
      }
    };

    TreeNode.prototype.focus = function() {
      return this.isFocused(true);
    };

    TreeNode.prototype.selectPrevious = function() {
      var previousSibling;
      if (!this.isRoot) {
        previousSibling = this.previousSibling();
        if (previousSibling) {
          while (previousSibling.isOpen() && previousSibling.children().length > 0) {
            previousSibling = previousSibling.children()[previousSibling.children().length - 1];
          }
          return previousSibling.select();
        } else {
          return this.parent().select();
        }
      }
    };

    TreeNode.prototype.selectNext = function() {
      var nextSibling, parent;
      var _this = this;
      if (this.isRoot) {
        return this.children.load(function() {
          if (_this.children().length > 0) return _this.children()[0].select();
        });
      } else {
        if (this.isOpen() && this.children().length > 0) {
          return this.children()[0].select();
        } else {
          nextSibling = this.nextSibling();
          if (nextSibling) {
            return nextSibling.select();
          } else {
            parent = this.parent();
            while (!parent.nextSibling() && !parent.isRoot) {
              parent = parent.parent();
            }
            if (parent.nextSibling()) return parent.nextSibling().select();
          }
        }
      }
    };

    TreeNode.prototype.addNewChild = function(options) {
      var _this = this;
      if (this.canAddChildren) {
        if (!options.type) options.type = this.childType || this.type;
        if (!options.name) options.name = this.defaultChildName;
        return this._executeHandler('onAddNewChild', options.type, options.name, function(data) {
          return _this.addChild(data, function() {
            if (_this.renameAfterAdd) return newNode.isRenaming(true);
          });
        });
      }
    };

    TreeNode.prototype.addChild = function(data, completed) {
      var newNode;
      var _this = this;
      if (data) {
        newNode = this._createChild(data);
        return this.children.load(function() {
          _this.open();
          _this.children.push(newNode);
          newNode.select();
          if (completed) return completed(newNode);
        });
      }
    };

    TreeNode.prototype._updateCheckState = function() {
      var c, childState, currentChildState, _i, _len, _ref;
      if (this.children().length > 0) {
        currentChildState = this.children()[0].checkState();
        _ref = this.children();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          c = _ref[_i];
          childState = c.checkState();
          if (childState !== currentChildState) {
            currentChildState = "mixed";
            break;
          }
          currentChildState = childState;
        }
        this.checkState(currentChildState);
      }
      if (!this.isRoot) return this.parent()._updateCheckState();
    };

    TreeNode.prototype._executeHandler = function() {
      var name, others;
      name = arguments[0], others = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return this.viewModel.options.handlers[name].apply(this, [this].concat(__slice.call(others)));
    };

    TreeNode.prototype._setOption = function(optionName) {
      var o, _i, _len, _ref, _ref2, _results;
      _ref2 = [this.data[optionName], (_ref = this.viewModel.options.nodeDefaults[this.type]) != null ? _ref[optionName] : void 0, this.viewModel.options.nodeDefaults[optionName]];
      _results = [];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        o = _ref2[_i];
        if (o != null) {
          this[optionName] = o;
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    TreeNode.prototype._createChild = function(data) {
      return new TreeNode(data, this, this.viewModel);
    };

    return TreeNode;

  })();

  TreeViewModel = (function() {

    function TreeViewModel(configuration) {
      this.options = jQuery.extend(true, {}, TreeViewModel.defaultOptions, configuration);
      this.selectedNode = ko.observable(null);
      this.checkedNodes = ko.observableArray();
      if (this.options.contextMenus) {
        this.contextMenu = new bo.ui.ContextMenu({
          contextMenus: this.options.contextMenus,
          build: function(event, dataItem) {
            dataItem.select();
            return {
              name: dataItem.type
            };
          }
        });
      }
      this.root = new TreeNode(this.options.root, null, this);
    }

    TreeViewModel.prototype.addChildren = function(children) {
      return this.root.setChildren(children);
    };

    return TreeViewModel;

  })();

  TreeViewModel.defaultOptions = {
    root: {
      name: 'Root',
      isOpen: true,
      children: [],
      canDelete: false,
      isDraggable: false
    },
    checksEnabled: false,
    nodeDefaults: {
      isDraggable: true,
      isDropTarget: true,
      canAddChildren: true,
      childType: 'folder',
      renameAfterAdd: true,
      canRename: false,
      canDelete: true,
      defaultChildName: 'New Node'
    },
    handlers: {
      onSelect: function(onSuccess) {
        return onSuccess();
      },
      onAddNewChild: function(type, name, onSuccess) {
        return onSuccess();
      },
      onRename: function(from, to, onSuccess) {
        return onSuccess();
      },
      onDelete: function(action, onSuccess) {
        return onSuccess();
      },
      onMove: function(newParent, onSuccess) {
        return onSuccess();
      },
      canAcceptDrop: function(node, droppable, defaultAcceptance) {
        return defaultAcceptance(droppable);
      },
      onAcceptUnknownDrop: function(node, droppable) {}
    }
  };

  bo.utils.addTemplate('treeNodeTemplate', '<li data-bind="command: [{ callback: selectPrevious, keyboard: \'up\' },\n                         { callback: open, keyboard: \'right\' },\n                         { callback: close, keyboard: \'left\' },\n                         { callback: selectNext, keyboard: \'down\' },\n                         { callback: deleteSelf, keyboard: \'del\' },\n                         { callback: beginRenaming, keyboard: \'f2\' }],\n                attr: { \'class\': cssClass }, \n                css: { \'tree-item\': true, leaf: isLeaf, open: isOpen, rename: isRenaming }">        \n    <div class="tree-node" \n         data-bind="draggable: isDraggable,\n                    dropTarget: { canAccept : canAcceptDrop, onDropComplete: acceptDrop}, \n                    contextMenu: contextMenu, \n                    hoverClass: \'ui-state-hover\',\n                    css: { \'ui-state-active\': isSelected, \'ui-state-focus\': isFocused, childrenLoading: children.isLoading }, \n                    event: { mousedown: select }">\n        <span data-bind="click: toggleFolder, \n                         css: { \'handle\': true, \'ui-icon\': true, \'ui-icon-triangle-1-se\': isOpen, \'ui-icon-triangle-1-e\': !isOpen() },\n                         bubble : false, \n                         style: { marginLeft: indent }">&nbsp;</span>\n\n        <!-- ko if: viewModel.options.checksEnabled -->\n            <input type="checkbox" class="checked" data-bind="hasfocus: isFocused, indeterminateCheckbox: checkState, visible: viewModel.options.checksEnabled" />\n            <span class="icon"></span>\n            <a href="javascript:void(0)" data-bind="visible: !isRenaming(), text: name" unselectable="on"></a>\n        <!-- /ko -->\n        <!-- ko ifnot: viewModel.options.checksEnabled -->\n            <span class="icon"></span>\n            <a href="javascript:void(0)" data-bind="hasfocus: isFocused, visible: !isRenaming(), text: name" unselectable="on"></a>\n        <!-- /ko -->\n\n        <input class="rename" type="text" data-bind="\n                   visible: isRenaming, \n                   value: editingName, \n                   valueUpdate: \'keyup\', \n                   hasfocus: isRenaming(), \n                   command: [{ callback: commitRenaming, event: \'blur\', keyboard: \'return\' },\n                             { callback: cancelRenaming, keyboard: \'esc\' }]" />\n    </div>\n    \n    <ul data-bind=\'visible: isOpen, template: { renderIf: isOpen, name: "treeNodeTemplate", foreach: children }\'></ul>\n</li>');

  bo.utils.addTemplate('treeTemplate', '<ul class="bo-tree" data-bind="template: { name : \'treeNodeTemplate\', data: root }"></ul>');

  ko.bindingHandlers.boTree = {
    init: function(element, viewModelAccessor) {
      var value;
      value = viewModelAccessor();
      return ko.renderTemplate("treeTemplate", value, {}, element, "replaceNode");
    }
  };

  bo.ui.Tree = TreeViewModel;

}).call(this);
