/*
 blackout - v2.0.0
 Copyright (c) 2012 Adam Barclay.
 Distributed under MIT license
 http://github.com/barclayadam/blackout
*/

var __hasProp = {}.hasOwnProperty;

(function(window, document, $, ko) {
  return (function(factory) {
    if (typeof require === "function" && typeof exports === "object" && typeof module === "object") {
      return factory(module["exports"] || exports);
    } else if (typeof define === "function" && define["amd"]) {
      return define(["exports"], factory);
    } else {
      return factory(window["bo"] = {});
    }
  })(function(boExports) {
    var EventBus, ExternalTemplateSource, RequestBuilder, Route, StringTemplateSource, ajax, bo, createCustomEngine, currentFragment, defineRegexValidator, emptyValue, getErrors, getLabelFor, getMessageCreator, hasPushState, hasValue, koBindingHandlers, labels, location, nativeHistory, nativePushState, nativeReplaceState, notifications, parseDate, regionManagerContextKey, requestDetectionFrame, root, routeStripper, rules, tagBindingProvider, templating, toOrderDirection, today, updateUri, uri, validateModel, validation, windowHistory, windowLocation, withoutTime, _getFragment, _getHash;
    if (ko === void 0) {
      throw new Error('knockout must be included before blackout.');
    }
    koBindingHandlers = ko.bindingHandlers;
    bo = boExports != null ? boExports : {};
    bo.log = {
      enabled: false
    };
    try {
      window.console.log();
    } catch (e) {
      window.console = {};
    }
    'debug info warn error'.replace(/\w+/g, function(n) {
      return bo.log[n] = function() {
        var _base;
        if (bo.log.enabled) {
          return typeof (_base = window.console[n] || window.console.log || function() {}).apply === "function" ? _base.apply(window.console, arguments) : void 0;
        }
      };
    });
    bo.utils = {
      toTitleCase: function(str) {
        var convertWord;
        if (str != null) {
          convertWord = function(match) {
            if (match.toUpperCase() === match) {
              return match;
            } else {
              match = match.replace(/([a-z])([A-Z0-9])/g, function(_, one, two) {
                return "" + one + " " + two;
              });
              match = match.replace(/\b([A-Z]+)([A-Z])([a-z])/, function(_, one, two, three) {
                return "" + one + " " + two + three;
              });
              return match = match.replace(/^./, function(s) {
                return s.toUpperCase();
              });
            }
          };
          return str.toString().replace(/\b[a-zA-Z0-9]+\b/g, convertWord);
        }
      },
      toSentenceCase: function(str) {
        var convertWord;
        if (str != null) {
          convertWord = function(match) {
            if (match.toUpperCase() === match) {
              return match;
            } else {
              match = match.replace(/([A-Z]{2,})([A-Z])$/g, function(_, one, two) {
                return " " + one + two;
              });
              match = match.replace(/([A-Z]{2,})([A-Z])([^$])/g, function(_, one, two, three) {
                return " " + one + " " + (two.toLowerCase()) + three;
              });
              match = match.replace(/([a-z])([A-Z0-9])/g, function(_, one, two) {
                return "" + one + " " + (two.toLowerCase());
              });
              match = match.replace(/^./, function(s) {
                return s.toLowerCase();
              });
              return match;
            }
          };
          str = str.toString();
          str = str.replace(/\b[a-zA-Z0-9]+\b/g, convertWord);
          str = str.replace(/^./, function(s) {
            return s.toUpperCase();
          });
          return str;
        }
      },
      asObservable: function(value) {
        if (ko.isObservable(value)) {
          return value;
        }
        if (_.isArray(value)) {
          return ko.observableArray(value);
        } else {
          return ko.observable(value);
        }
      }
    };
    EventBus = function() {
      var clearAll, publish, subscribe, _subscribers;
      _subscribers = {};
      clearAll = function() {
        return _subscribers = {};
      };
      subscribe = function(messageName, callback) {
        var message, newToken, _i, _len;
        if (_.isArray(messageName)) {
          for (_i = 0, _len = messageName.length; _i < _len; _i++) {
            message = messageName[_i];
            subscribe(message, callback);
          }
          return void 0;
        } else {
          if (_subscribers[messageName] === void 0) {
            _subscribers[messageName] = {};
          }
          newToken = _.size(_subscribers[messageName]);
          _subscribers[messageName][newToken] = callback;
          return {
            unsubscribe: function() {
              return delete _subscribers[messageName][newToken];
            }
          };
        }
      };
      publish = function(messageName, args) {
        var indexOfSeparator, messages, msg, subscriber, t, _i, _len, _ref;
        if (args == null) {
          args = {};
        }
        bo.log.debug("Publishing " + messageName, args);
        indexOfSeparator = -1;
        messages = [messageName];
        while (messageName = messageName.substring(0, messageName.lastIndexOf(':'))) {
          messages.push(messageName);
        }
        for (_i = 0, _len = messages.length; _i < _len; _i++) {
          msg = messages[_i];
          _ref = _subscribers[msg] || {};
          for (t in _ref) {
            subscriber = _ref[t];
            subscriber.call(this, args);
          }
        }
        return void 0;
      };
      return {
        clearAll: clearAll,
        subscribe: subscribe,
        publish: publish
      };
    };
    bo.EventBus = EventBus;
    bo.bus = new bo.EventBus;
    bo.Uri = (function() {
      var convertToType, decode, encode, objectToQuery, queryStringVariable, queryToObject, standardPorts;

      encode = encodeURIComponent;

      decode = decodeURIComponent;

      standardPorts = {
        http: 80,
        https: 443
      };

      queryStringVariable = function(name, value) {
        var t;
        t = encode(name);
        value = value.toString();
        if (value.length > 0) {
          t += "=" + encode(value);
        }
        return t;
      };

      objectToQuery = function(variables) {
        var name, tmp, v, val, _i, _len;
        tmp = [];
        for (name in variables) {
          val = variables[name];
          if (val !== null) {
            if (_.isArray(val)) {
              for (_i = 0, _len = val.length; _i < _len; _i++) {
                v = val[_i];
                if (v !== null) {
                  tmp.push(queryStringVariable(name, v));
                }
              }
            } else {
              tmp.push(queryStringVariable(name, val));
            }
          }
        }
        return tmp.length && tmp.join("&");
      };

      convertToType = function(value) {
        var asNumber, valueLower;
        if (!(value != null)) {
          return void 0;
        }
        valueLower = value.toLowerCase();
        if (valueLower === 'true' || valueLower === 'false') {
          return value === 'true';
        }
        asNumber = parseFloat(value);
        if (!_.isNaN(asNumber)) {
          return asNumber;
        }
        return value;
      };

      queryToObject = function(qs) {
        var key, p, query, split, value, _i, _len, _ref;
        if (!qs) {
          return {};
        }
        qs = qs.replace(/^[^?]*\?/, '');
        qs = qs.replace(/&$/, '');
        qs = qs.replace(/\+/g, ' ');
        query = {};
        _ref = qs.split('&');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          split = p.split('=');
          key = decode(split[0]);
          value = convertToType(decode(split[1]));
          if (query[key]) {
            if (!_.isArray(query[key])) {
              query[key] = [query[key]];
            }
            query[key].push(value);
          } else {
            query[key] = value;
          }
        }
        return query;
      };

      function Uri(uri, options) {
        var anchor, _ref, _ref1;
        if (options == null) {
          options = {
            decode: true
          };
        }
        this.variables = {};
        anchor = document.createElement('a');
        anchor.href = uri;
        this.path = anchor.pathname;
        if (options.decode === true) {
          this.path = decode(this.path);
        }
        if (this.path.charAt(0) !== '/') {
          this.path = "/" + this.path;
        }
        this.fragment = (_ref = anchor.hash) != null ? _ref.substring(1) : void 0;
        this.query = (_ref1 = anchor.search) != null ? _ref1.substring(1) : void 0;
        this.variables = queryToObject(this.query);
        if (uri.charAt(0) === '/' || uri.charAt(0) === '.') {
          this.isRelative = true;
        } else {
          this.isRelative = false;
          this.scheme = anchor.protocol;
          this.scheme = this.scheme.substring(0, this.scheme.length - 1);
          this.port = parseInt(anchor.port, 10);
          this.host = anchor.hostname;
          if (standardPorts[this.scheme] === this.port) {
            this.port = null;
          }
        }
      }

      Uri.prototype.clone = function() {
        return new bo.Uri(this.toString());
      };

      Uri.prototype.toString = function() {
        var q, s;
        s = "";
        q = objectToQuery(this.variables);
        if (this.scheme) {
          s = this.scheme + "://";
        }
        if (this.host) {
          s += this.host;
        }
        if (this.port) {
          s += ":" + this.port;
        }
        if (this.path) {
          s += this.path;
        }
        if (q) {
          s += "?" + q;
        }
        if (this.fragment) {
          s += "#" + this.fragment;
        }
        return s;
      };

      return Uri;

    })();
    ajax = bo.ajax = {};
    requestDetectionFrame = [];
    RequestBuilder = (function() {
      var doCall;

      doCall = function(httpMethod, requestBuilder) {
        var ajaxRequest, failureHandlerRegistered, getDeferred, promise, requestOptions;
        getDeferred = $.Deferred();
        failureHandlerRegistered = false;
        requestOptions = _.defaults(requestBuilder.properties, {
          url: requestBuilder.url,
          type: httpMethod
        });
        ajaxRequest = $.ajax(requestOptions);
        bo.bus.publish("ajaxRequestSent:" + requestBuilder.url, {
          path: requestBuilder.url,
          method: httpMethod
        });
        ajaxRequest.done(function(response) {
          bo.bus.publish("ajaxResponseReceived:success:" + requestBuilder.url, {
            path: requestBuilder.url,
            method: httpMethod,
            response: response,
            status: 200
          });
          return getDeferred.resolve(response);
        });
        ajaxRequest.fail(function(response) {
          var failureMessage;
          failureMessage = {
            path: requestBuilder.url,
            method: httpMethod,
            responseText: response.responseText,
            status: response.status
          };
          bo.bus.publish("ajaxResponseReceived:failure:" + requestBuilder.url, failureMessage);
          if (!failureHandlerRegistered) {
            bo.bus.publish("ajaxResponseFailureUnhandled:" + requestBuilder.url, failureMessage);
          }
          return getDeferred.reject(response);
        });
        promise = getDeferred.promise();
        promise.fail = function(callback) {
          failureHandlerRegistered = true;
          return getDeferred.fail(callback);
        };
        requestDetectionFrame.push(promise);
        return promise;
      };

      function RequestBuilder(url) {
        this.url = url;
        this.properties = {};
      }

      RequestBuilder.prototype.get = function() {
        return doCall('GET', this);
      };

      RequestBuilder.prototype.post = function() {
        return doCall('POST', this);
      };

      RequestBuilder.prototype.put = function() {
        return doCall('PUT', this);
      };

      RequestBuilder.prototype["delete"] = function() {
        return doCall('DELETE', this);
      };

      RequestBuilder.prototype.head = function() {
        return doCall('HEAD', this);
      };

      return RequestBuilder;

    })();
    ajax.url = function(url) {
      return new RequestBuilder(url);
    };
    ajax.listen = function(f) {
      requestDetectionFrame = [];
      f();
      return $.when.apply(this, requestDetectionFrame);
    };
    "local session".replace(/\w+/g, function(type) {
      return ko.extenders[type + 'Storage'] = function(target, key) {
        var stored;
        stored = window[type + 'Storage'].getItem(key);
        if (stored != null) {
          target((JSON.parse(stored)).value);
        }
        target.subscribe(function(newValue) {
          return window[type + 'Storage'].setItem(key, JSON.stringify({
            value: newValue
          }));
        });
        return target;
      };
    });
    notifications = bo.notifications = {};
    'success warning error'.replace(/\w+/g, function(level) {
      return notifications[level] = function(text) {
        return bo.bus.publish("notification:" + level, {
          text: text,
          level: level
        });
      };
    });
    templating = bo.templating = {};
    StringTemplateSource = (function() {

      function StringTemplateSource(templateName) {
        this.templateName = templateName;
      }

      StringTemplateSource.prototype.text = function(value) {
        return ko.utils.unwrapObservable(templating.templates[this.templateName]);
      };

      return StringTemplateSource;

    })();
    ExternalTemplateSource = (function() {

      function ExternalTemplateSource(templateName) {
        this.templateName = templateName;
        this.stringTemplateSource = new StringTemplateSource(this.templateName);
      }

      ExternalTemplateSource.prototype.text = function(value) {
        var loadingPromise, template;
        if (templating.templates[this.templateName] === void 0) {
          template = ko.observable(templating.loadingTemplate);
          templating.set(this.templateName, template);
          loadingPromise = templating.loadExternalTemplate(this.templateName);
          loadingPromise.done(template);
        }
        return this.stringTemplateSource.text.apply(this.stringTemplateSource, arguments);
      };

      return ExternalTemplateSource;

    })();
    createCustomEngine = function(templateEngine) {
      var originalMakeTemplateSource;
      originalMakeTemplateSource = templateEngine.makeTemplateSource;
      templateEngine.makeTemplateSource = function(template) {
        if (templating.templates[template] != null) {
          return new StringTemplateSource(template);
        } else if (templating.isExternal(template)) {
          return new ExternalTemplateSource(template);
        } else {
          return originalMakeTemplateSource(template);
        }
      };
      return templateEngine;
    };
    ko.setTemplateEngine(createCustomEngine(new ko.nativeTemplateEngine()));
    templating.loadingTemplate = 'Loading...';
    templating.isExternal = function(name) {
      return name.indexOf && name.indexOf('e:' === 0);
    };
    templating.externalPath = '/Templates/Get/{name}';
    templating.loadExternalTemplate = function(name) {
      var path;
      name = name.substring(2);
      path = templating.externalPath.replace('{name}', name);
      return bo.ajax.url(path).get();
    };
    templating.reset = function() {
      return templating.templates = {
        _data: {}
      };
    };
    templating.set = function(name, template) {
      if (ko.isWriteableObservable(templating.templates[name])) {
        return templating.templates[name](template);
      } else {
        return templating.templates[name] = template;
      }
    };
    templating.reset();
    validation = bo.validation = {};
    getMessageCreator = function(propertyRules, ruleName) {
      return propertyRules["" + ruleName + "Message"] || bo.validation.rules[ruleName].message || "The field is invalid";
    };
    validation.formatErrorMessage = function(msg) {
      return msg;
    };
    getErrors = function(observableValue) {
      var errors, isValid, msgCreator, rule, ruleName, ruleOptions, rules, value;
      errors = [];
      rules = observableValue.validationRules;
      value = observableValue.peek();
      for (ruleName in rules) {
        ruleOptions = rules[ruleName];
        rule = bo.validation.rules[ruleName];
        if (rule != null) {
          isValid = rule.validator(value, ruleOptions);
          if (!isValid) {
            msgCreator = getMessageCreator(rules, ruleName);
            if (_.isFunction(msgCreator)) {
              errors.push(validation.formatErrorMessage(msgCreator(ruleOptions)));
            } else {
              errors.push(validation.formatErrorMessage(msgCreator));
            }
          }
        }
      }
      return errors;
    };
    validateModel = function(model) {
      var item, propName, propValue, unwrapped, valid, _i, _len;
      valid = true;
      if (model != null) {
        if ((model.validate != null) && (model.validationRules != null)) {
          model.validate();
          valid = model.isValid() && valid;
        }
        if (ko.isObservable(model)) {
          unwrapped = model.peek();
        } else {
          unwrapped = model;
        }
        if (_.isObject(unwrapped)) {
          for (propName in unwrapped) {
            if (!__hasProp.call(unwrapped, propName)) continue;
            propValue = unwrapped[propName];
            valid = (validateModel(propValue)) && valid;
          }
        }
        if (_.isArray(unwrapped)) {
          for (_i = 0, _len = unwrapped.length; _i < _len; _i++) {
            item = unwrapped[_i];
            validateModel(item);
          }
        }
      }
      return valid;
    };
    validation.mixin = function(model) {
      model.validate = function() {
        if (!model.validated()) {
          ko.computed(function() {
            return model.isValid(validateModel(model));
          });
          model.validated(true);
        }
        return model.serverErrors([]);
      };
      model.validated = ko.observable(false);
      model.isValid = ko.observable();
      model.serverErrors = ko.observable([]);
      return model.setServerErrors = function(errors) {
        var key, value;
        for (key in model) {
          if (!__hasProp.call(model, key)) continue;
          value = model[key];
          if ((value != null ? value.serverErrors : void 0) != null) {
            value.serverErrors(_.flatten([errors[key]] || []));
            delete errors[key];
          }
        }
        return model.serverErrors(_.flatten(_.values(errors)));
      };
    };
    validation.newModel = function(model) {
      if (model == null) {
        model = {};
      }
      validation.mixin(model);
      return model;
    };
    ko.extenders.validationRules = function(target, validationRules) {
      var validate;
      if (validationRules == null) {
        validationRules = {};
      }
      target.validationRules = validationRules;
      target.validate = function() {
        return target.validated(true);
      };
      target.validated = ko.observable(false);
      target.errors = ko.observable([]);
      target.isValid = ko.observable(true);
      target.serverErrors = ko.observable([]);
      validate = function() {
        target.serverErrors([]);
        target.errors(getErrors(target));
        return target.isValid(target.errors().length === 0);
      };
      target.subscribe(function() {
        return validate();
      });
      validate();
      return target;
    };
    ko.subscribable.fn.addValidationRules = function(validationRules) {
      return ko.extenders.validationRules(this, validationRules);
    };
    hasValue = function(value) {
      return (value != null) && (!value.replace || value.replace(/[ ]/g, '') !== '');
    };
    emptyValue = function(value) {
      return !hasValue(value);
    };
    parseDate = function(value) {
      if (_.isDate(value)) {
        return value;
      }
    };
    withoutTime = function(dateTime) {
      if (dateTime != null) {
        return new Date(dateTime.getYear(), dateTime.getMonth(), dateTime.getDate());
      }
    };
    today = function() {
      return withoutTime(new Date());
    };
    labels = document.getElementsByTagName('label');
    getLabelFor = function(element) {
      return _.find(labels, function(l) {
        return l.getAttribute('for') === element.id;
      });
    };
    rules = {
      required: {
        validator: function(value, options) {
          return hasValue(value);
        },
        message: "This field is required",
        modifyElement: function(element, options) {
          var label;
          element.setAttribute("aria-required", "true");
          element.setAttribute("required", "required");
          label = getLabelFor(element);
          if (label) {
            return ko.utils.toggleDomNodeCssClass(element, 'required', true);
          }
        }
      },
      regex: {
        validator: function(value, options) {
          return (emptyValue(value)) || (options.test(value));
        },
        message: "This field is invalid",
        modifyElement: function(element, options) {
          return element.setAttribute("pattern", "" + options);
        }
      },
      numeric: {
        validator: function(value, options) {
          return (emptyValue(value)) || (isFinite(value));
        },
        message: function(options) {
          return "This field must be numeric";
        },
        modifyElement: function(element, options) {
          return element.setAttribute("type", 'numeric');
        }
      },
      integer: {
        validator: function(value, options) {
          return (emptyValue(value)) || (/^[0-9]+$/.test(value));
        },
        message: "This field must be a whole number",
        modifyElement: function(element, options) {
          return element.setAttribute("type", 'numeric');
        }
      },
      exactLength: {
        validator: function(value, options) {
          return (emptyValue(value)) || ((value.length != null) && value.length === options);
        },
        message: function(options) {
          return "This field must be exactly " + options + " characters long";
        },
        modifyElement: function(element, options) {
          return element.setAttribute("maxLength", options);
        }
      },
      minLength: {
        validator: function(value, options) {
          return (emptyValue(value)) || ((value.length != null) && value.length >= options);
        },
        message: function(options) {
          return "This field must be at least " + options + " characters long";
        }
      },
      maxLength: {
        validator: function(value, options) {
          return (emptyValue(value)) || ((value.length != null) && value.length <= options);
        },
        message: function(options) {
          return "This field must be no more than " + options + " characters long";
        },
        modifyElement: function(element, options) {
          return element.setAttribute("maxLength", options);
        }
      },
      rangeLength: {
        validator: function(value, options) {
          return (rules.minLength.validator(value, options[0])) && (rules.maxLength.validator(value, options[1]));
        },
        message: function(options) {
          return "This field must be between " + options[0] + " and " + options[1] + " characters long";
        },
        modifyElement: function(element, options) {
          return element.setAttribute("maxLength", "" + options[1]);
        }
      },
      min: {
        validator: function(value, options) {
          return (emptyValue(value)) || (value >= options);
        },
        message: function(options) {
          return "This field must be equal to or greater than " + options;
        },
        modifyElement: function(element, options) {
          element.setAttribute("min", options);
          return element.setAttribute("aria-valuemin", options);
        }
      },
      moreThan: {
        validator: function(value, options) {
          return (emptyValue(value)) || (value > options);
        },
        message: function(options) {
          return "This field must be greater than " + options + ".";
        }
      },
      max: {
        validator: function(value, options) {
          return (emptyValue(value)) || (value <= options);
        },
        message: function(options) {
          return "This field must be equal to or less than " + options;
        },
        modifyElement: function(element, options) {
          element.setAttribute("max", options);
          return element.setAttribute("aria-valuemax", options);
        }
      },
      lessThan: {
        validator: function(value, options) {
          return (emptyValue(value)) || (value < options);
        },
        message: function(options) {
          return "This field must be less than " + options + ".";
        }
      },
      range: {
        validator: function(value, options) {
          return (rules.min.validator(value, options[0])) && (rules.max.validator(value, options[1]));
        },
        message: function(options) {
          return "This field must be between " + options[0] + " and " + options[1];
        },
        modifyElement: function(element, options) {
          rules.min.modifyElement(element, options[0]);
          return rules.max.modifyElement(element, options[1]);
        }
      },
      maxDate: {
        validator: function(value, options) {
          return (emptyValue(value)) || (parseDate(value) <= parseDate(options));
        },
        message: function(options) {
          return "This field must be on or before " + options[0];
        }
      },
      minDate: {
        validator: function(value, options) {
          return (emptyValue(value)) || (parseDate(value) >= parseDate(options));
        },
        message: function(options) {
          return "This field must be on or after " + options[0];
        }
      },
      inFuture: {
        validator: function(value, options) {
          if (options === "Date") {
            return (emptyValue(value)) || (withoutTime(parseDate(value)) > today());
          } else {
            return (emptyValue(value)) || (parseDate(value) > new Date());
          }
        },
        message: "This field must be in the future"
      },
      inPast: {
        validator: function(value, options) {
          if (options === "Date") {
            return (emptyValue(value)) || (withoutTime(parseDate(value)) < today());
          } else {
            return (emptyValue(value)) || (parseDate(value) < new Date());
          }
        },
        message: "This field must be in the past"
      },
      notInPast: {
        validator: function(value, options) {
          if (options === "Date") {
            return (emptyValue(value)) || (withoutTime(parseDate(value)) >= today());
          } else {
            return (emptyValue(value)) || (parseDate(value) >= new Date());
          }
        },
        message: "This field must not be in the past"
      },
      notInFuture: {
        validator: function(value, options) {
          if (options === "Date") {
            return (emptyValue(value)) || (withoutTime(parseDate(value)) <= today());
          } else {
            return (emptyValue(value)) || (parseDate(value) <= new Date());
          }
        },
        message: "This field must not be in the future"
      },
      requiredIf: {
        validator: function(value, options) {
          var valueToCheckAgainst, valueToCheckAgainstInList;
          if (options.equalsOneOf === void 0) {
            throw new Error("You need to provide a list of items to check against.");
          }
          if (options.value === void 0) {
            throw new Error("You need to provide a value.");
          }
          valueToCheckAgainst = (ko.utils.unwrapObservable(options.value)) || null;
          valueToCheckAgainstInList = _.any(options.equalsOneOf, function(v) {
            return (v || null) === valueToCheckAgainst;
          });
          if (valueToCheckAgainstInList) {
            return hasValue(value);
          } else {
            return true;
          }
        },
        message: "This field is required"
      },
      requiredIfNot: {
        validator: function(value, options) {
          var valueToCheckAgainst, valueToCheckAgainstNotInList;
          if (options.equalsOneOf === void 0) {
            throw new Error("You need to provide a list of items to check against.");
          }
          if (options.value === void 0) {
            throw new Error("You need to provide a value.");
          }
          valueToCheckAgainst = (ko.utils.unwrapObservable(options.value)) || null;
          valueToCheckAgainstNotInList = _.all(options.equalsOneOf, function(v) {
            return (v || null) !== valueToCheckAgainst;
          });
          if (valueToCheckAgainstNotInList) {
            return hasValue(value);
          } else {
            return true;
          }
        },
        message: "This field is required"
      },
      equalTo: {
        validator: function(value, options) {
          return (emptyValue(value)) || (value === ko.utils.unwrapObservable(options));
        },
        message: function(options) {
          return "This field must be equal to " + options + ".";
        }
      },
      custom: {
        validator: function(value, options) {
          if (!_.isFunction(options)) {
            throw new Error("Must pass a function to the 'custom' validator");
          }
          return options(value);
        },
        message: "This field is invalid."
      }
    };
    defineRegexValidator = function(name, regex) {
      return rules[name] = {
        validator: function(value, options) {
          return rules.regex.validator(value, regex);
        },
        message: "This field is an invalid " + name,
        modifyElement: function(element, options) {
          return rules.regex.modifyElement(element, regex);
        }
      };
    };
    defineRegexValidator('email', /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/i);
    defineRegexValidator('postcode', /(GIR ?0AA)|((([A-Z][0-9]{1,2})|(([A-Z][A-HJ-Y][0-9]{1,2})|(([A-Z][0-9][A-Z])|([A-Z][A-HJ-Y][0-9]?[A-Z])))) ?[0-9][A-Z]{2})/i);
    bo.validation.rules = rules;
    toOrderDirection = function(order) {
      if (order === void 0 || order === 'asc' || order === 'ascending') {
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
        this._sortByAsString = ko.observable();
        this._sortByDetails = ko.observable();
        this._sortByDetails.subscribe(function(newValue) {
          var normalised;
          normalised = _.reduce(newValue, (function(memo, o) {
            var prop;
            prop = "" + o.name + " " + (toOrderDirection(o.order));
            if (memo) {
              return "" + memo + ", " + prop;
            } else {
              return prop;
            }
          }), '');
          return _this._sortByAsString(normalised);
        });
        this.sortBy = ko.computed({
          read: this._sortByAsString,
          write: function(value) {
            var properties;
            properties = _(value.split(',')).map(function(p) {
              var indexOfSpace;
              p = ko.utils.stringTrim(p);
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
            return _this._sortByDetails(properties);
          }
        });
        this.items = ko.computed(function() {
          if ((_this._sortByDetails() != null) && !_this._serverPagingEnabled) {
            return _this._loadedItems().sort(function(a, b) {
              var p, _i, _len, _ref;
              _ref = _this._sortByDetails();
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                p = _ref[_i];
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
          } else {
            return _this._loadedItems();
          }
        });
        if (this.options.searchParameters != null) {
          this.searchParameters = ko.computed(function() {
            return ko.toJS(options.searchParameters);
          });
          this.searchParameters.subscribe(function() {
            if (_this._hasLoadedOnce) {
              return _this.load();
            }
          });
        } else {
          this.searchParameters = ko.observable({});
        }
        this._setupPaging();
        this._setupInitialData();
      }

      DataSource.prototype.getPropertySortOrder = function(propertyName) {
        var ordering, sortedBy;
        sortedBy = this._sortByDetails();
        if ((sortedBy != null) && sortedBy.length > 0) {
          ordering = _.find(sortedBy, function(o) {
            return o.name === propertyName;
          });
          return ordering != null ? ordering.order : void 0;
        }
      };

      DataSource.prototype.remove = function(item) {
        return this._loadedItems.remove(item);
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
        if (!this.isLastPage()) {
          return this.goTo(this.pageNumber() + 1);
        }
      };

      DataSource.prototype.goToPreviousPage = function() {
        if (!this.isFirstPage()) {
          return this.goTo(this.pageNumber() - 1);
        }
      };

      DataSource.prototype._setupInitialData = function() {
        if ((this.options.provider != null) && _.isArray(this.options.provider)) {
          this._setData(this.options.provider);
          this.goTo(1);
        }
        if (this.options.initialSortOrder != null) {
          this.sortBy(this.options.initialSortOrder);
        }
        if (this.options.autoLoad === true) {
          return this.load();
        }
      };

      DataSource.prototype._setupPaging = function() {
        var _this = this;
        this._lastProviderOptions = -1;
        this.clientPagesPerServerPage = this.options.serverPaging / (this.options.clientPaging || this.options.serverPaging);
        this.pageSize = ko.observable();
        this.totalCount = ko.observable(0);
        this.pageNumber = ko.observable().extend({
          publishable: {
            message: (function(p) {
              return "pageChanged:" + (p());
            }),
            bus: this
          }
        });
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
          if (_this.totalCount()) {
            return Math.ceil(_this.totalCount() / _this.pageSize());
          } else {
            return 0;
          }
        });
        this.isFirstPage = ko.computed(function() {
          return _this.pageNumber() === 1;
        });
        this.isLastPage = ko.computed(function() {
          return _this.pageNumber() === _this.pageCount() || _this.pageCount() === 0;
        });
        if (this.options.serverPaging) {
          this.pageNumber.subscribe(function() {
            return _this._doLoad();
          });
          return this.sortBy.subscribe(function() {
            return _this._doLoad();
          });
        }
      };

      DataSource.prototype._doLoad = function() {
        var loadOptions,
          _this = this;
        if (_.isArray(this.options.provider)) {
          return;
        }
        loadOptions = _.extend({}, this.searchParameters());
        if (this._serverPagingEnabled) {
          loadOptions.pageSize = this.options.serverPaging;
          loadOptions.pageNumber = Math.ceil(this.pageNumber() / this.clientPagesPerServerPage);
        }
        if (this.sortBy() != null) {
          loadOptions.orderBy = this.sortBy();
        }
        if (_.isEqual(loadOptions, this._lastProviderOptions)) {
          return;
        }
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
          this.totalCount(loadedData.totalCount || loadedData.totalItems || 0);
        } else {
          items = loadedData;
          this.pageSize(this.options.clientPaging || loadedData.length);
          this.totalCount(loadedData.length);
        }
        if (this.options.map != null) {
          items = _.chain(items).map(this.options.map).compact().value();
        }
        this._loadedItems(items);
        return this._hasLoadedOnce = true;
      };

      return DataSource;

    })();
    location = bo.location = {};
    windowHistory = window.history;
    windowLocation = window.location;
    routeStripper = /^[#\/]/;
    hasPushState = !!(windowHistory && windowHistory.pushState);
    _getHash = function() {
      var match;
      match = windowLocation.href.match(/#(.*)$/);
      if (match) {
        return match[1];
      } else {
        return "";
      }
    };
    _getFragment = function() {
      var fragment;
      if (hasPushState) {
        fragment = windowLocation.pathname;
        fragment += windowLocation.search || '';
      } else {
        fragment = _getHash();
      }
      fragment.replace(routeStripper, "");
      fragment = fragment.replace(/\/\//g, '/');
      if (fragment.charAt(0) !== '/') {
        fragment = "/" + fragment;
      }
      fragment;

      return decodeURI(fragment);
    };
    uri = location.uri = ko.observable();
    updateUri = function() {
      return location.uri(new bo.Uri(document.location.toString()));
    };
    updateUri();
    location.host = function() {
      return uri().host;
    };
    location.path = ko.computed(function() {
      return uri().path;
    });
    location.fragment = ko.computed(function() {
      return uri().fragment || '';
    });
    location.query = ko.computed(function() {
      return uri().query;
    });
    location.variables = ko.computed(function() {
      return uri().variables;
    });
    location.routeVariables = ko.computed({
      read: function() {
        uri();
        return new bo.Uri(_getFragment()).variables;
      },
      deferEvaluation: true
    });
    location.routeVariables.set = function(key, value, options) {
      var currentUri;
      currentUri = new bo.Uri(location.routePath());
      currentUri.variables[key] = value;
      return location.routePath(currentUri.toString(), {
        replace: options.history === false
      });
    };
    location.routePath = ko.computed({
      read: function() {
        uri();
        return new bo.Uri(_getFragment()).path;
      },
      write: function(newPath, options) {
        if (options == null) {
          options = {};
        }
        if (location.routePath() === newPath) {
          return false;
        }
        if (options.replace === true) {
          windowHistory.replaceState(null, document.title, newPath);
        } else {
          windowHistory.pushState(null, document.title, newPath);
        }
        updateUri();
        return bo.bus.publish('urlChanged:internal', {
          url: _getFragment(),
          path: location.routePath(),
          variables: location.routeVariables(),
          external: false
        });
      }
    });
    location.reset = function() {
      return updateUri();
    };
    ko.utils.registerEventHandler(window, 'popstate', function() {
      updateUri();
      return bo.bus.publish('urlChanged:external', {
        url: _getFragment(),
        path: location.routePath(),
        variables: location.routeVariables(),
        external: true
      });
    });
    if (!hasPushState) {
      currentFragment = void 0;
      if (!hasPushState && window.onhashchange !== void 0) {
        ko.utils.registerEventHandler(window, 'hashchange', function() {
          var current;
          current = _getFragment();
          if (current !== currentFragment) {
            if (!hasPushState) {
              ko.utils.triggerEvent(window, 'popstate');
            }
            return currentFragment = current;
          }
        });
      }
      windowHistory.pushState = function(_, title, frag) {
        windowLocation.hash = frag;
        document.title = title;
        return updateUri();
      };
      windowHistory.replaceState = function(_, title, frag) {
        windowLocation.replace(windowLocation.toString().replace(/#.*$/, '') + '#' + frag);
        document.title = title;
        return updateUri();
      };
    } else {
      nativeHistory = windowHistory;
      nativePushState = windowHistory.pushState;
      nativeReplaceState = windowHistory.replaceState;
      windowHistory.pushState = function(state, title, frag) {
        nativePushState.call(nativeHistory, state, title, frag);
        document.title = title;
        return updateUri();
      };
      windowHistory.replaceState = function(state, title, frag) {
        nativeReplaceState.call(nativeHistory, state, title, frag);
        document.title = title;
        return updateUri();
      };
    }
    bo.routing = {};
    Route = (function() {
      var paramRegex;

      paramRegex = /{(\*?)(\w+)}/g;

      function Route(name, url, callback, options) {
        var routeDefinitionAsRegex,
          _this = this;
        this.name = name;
        this.url = url;
        this.callback = callback;
        this.options = options;
        this.title = options.title;
        this.requiredParams = [];
        this.paramNames = [];
        routeDefinitionAsRegex = this.url.replace(paramRegex, function(_, mode, name) {
          _this.paramNames.push(name);
          if (mode !== '*') {
            _this.requiredParams.push(name);
          }
          if (mode === '*') {
            return '(.*)';
          } else {
            return '([^/]*)';
          }
        });
        if (routeDefinitionAsRegex.length > 1 && routeDefinitionAsRegex.charAt(0) === '/') {
          routeDefinitionAsRegex = routeDefinitionAsRegex.substring(1);
        }
        this.incomingMatcher = new RegExp("" + routeDefinitionAsRegex + "/?$", "i");
      }

      Route.prototype.match = function(path) {
        var index, matches, name, params, _i, _len, _ref;
        matches = path.match(this.incomingMatcher);
        if (matches) {
          params = {};
          _ref = this.paramNames;
          for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
            name = _ref[index];
            params[name] = matches[index + 1];
          }
          return params;
        }
      };

      Route.prototype.buildUrl = function(parameters) {
        var _this = this;
        if (parameters == null) {
          parameters = {};
        }
        if (this._allRequiredParametersPresent(parameters)) {
          return this.url.replace(paramRegex, function(_, mode, name) {
            return ko.utils.unwrapObservable(parameters[name] || '');
          });
        }
      };

      Route.prototype._allRequiredParametersPresent = function(parameters) {
        return _.all(this.requiredParams, function(p) {
          return parameters[p] != null;
        });
      };

      Route.prototype.toString = function() {
        return "" + this.name + ": " + this.url;
      };

      return Route;

    })();
    root = '/';
    bo.routing.Router = (function() {

      function Router() {
        var _this = this;
        this.routes = {};
        bo.bus.subscribe('urlChanged:external', function(msg) {
          var matchedRoute;
          matchedRoute = _this.getRouteFromUrl(msg.url);
          if (matchedRoute === void 0) {
            return bo.bus.publish('routeNotFound', {
              url: msg.url
            });
          } else {
            return _this._doNavigate(msg.path, matchedRoute.route, matchedRoute.parameters);
          }
        });
      }

      Router.prototype._doNavigate = function(url, route, parameters) {
        if (typeof route.callback === "function") {
          route.callback(parameters);
        }
        bo.bus.publish("routeNavigated:" + route.name, {
          route: route,
          parameters: parameters
        });
        return this.currentUrl = url;
      };

      Router.prototype.route = function(name, url, callback, options) {
        if (options == null) {
          options = {
            title: name
          };
        }
        this.routes[name] = new Route(name, url, callback, options);
        return this;
      };

      Router.prototype.getRouteFromUrl = function(url) {
        var match, matchedParams, name, path, r, _ref;
        path = (new bo.Uri(url, {
          decode: true
        })).path;
        match = void 0;
        _ref = this.routes;
        for (name in _ref) {
          r = _ref[name];
          matchedParams = r.match(path);
          if (matchedParams != null) {
            match = {
              route: r,
              parameters: matchedParams
            };
          }
        }
        return match;
      };

      Router.prototype.getNamedRoute = function(name) {
        return this.routes[name];
      };

      Router.prototype.navigateTo = function(name, parameters) {
        var route, url;
        if (parameters == null) {
          parameters = {};
        }
        url = this.buildUrl(name, parameters);
        if (url != null) {
          route = this.getNamedRoute(name);
          this._doNavigate(url, route, parameters);
          bo.location.routePath(url);
          document.title = route.title;
          return true;
        }
        return false;
      };

      Router.prototype.buildUrl = function(name, parameters) {
        var route, url;
        route = this.getNamedRoute(name);
        url = route != null ? route.buildUrl(parameters) : void 0;
        if (route === void 0) {
          bo.log.warn("The route '" + name + "' could not be found.");
        }
        if (url === void 0) {
          bo.log.warn("The parameters specified are not valid for the '" + name + "' route.");
        }
        return url;
      };

      return Router;

    })();
    tagBindingProvider = function() {
      var findTagCompatibleBindingHandlerNames, mergeAllAttributes, processBindingHandlerTagDefinition, processOptions, realBindingProvider;
      realBindingProvider = new ko.bindingProvider();
      processBindingHandlerTagDefinition = function(bindingHandler) {
        var split;
        if (_.isString(bindingHandler.tag)) {
          split = bindingHandler.tag.split("->");
          if (split.length === 1) {
            return bindingHandler.tag = {
              appliesTo: split[0].toUpperCase()
            };
          } else {
            return bindingHandler.tag = {
              appliesTo: split[0].toUpperCase(),
              replacedWith: split[1]
            };
          }
        }
      };
      mergeAllAttributes = function(source, destination) {
        var attr, _i, _len, _ref, _results;
        if (document.body.mergeAttributes) {
          return destination.mergeAttributes(source, false);
        } else {
          _ref = source.attributes;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            attr = _ref[_i];
            _results.push(destination.setAttribute(attr.name, attr.value));
          }
          return _results;
        }
      };
      findTagCompatibleBindingHandlerNames = function(node) {
        var tagName;
        if (node.tagHandlers != null) {
          return node.tagHandlers;
        } else {
          tagName = node.tagName;
          if (tagName != null) {
            return _.filter(_.keys(koBindingHandlers), function(key) {
              var bindingHandler, _ref;
              bindingHandler = koBindingHandlers[key];
              processBindingHandlerTagDefinition(bindingHandler);
              return ((_ref = bindingHandler.tag) != null ? _ref.appliesTo : void 0) === tagName;
            });
          } else {
            return [];
          }
        }
      };
      processOptions = function(node, tagBindingHandlerName, bindingContext) {
        var options, optionsAttribute;
        options = true;
        optionsAttribute = node.getAttribute('data-option');
        if (optionsAttribute) {
          optionsAttribute = "" + tagBindingHandlerName + ": " + optionsAttribute;
          options = realBindingProvider.parseBindingsString(optionsAttribute, bindingContext);
          options = options[tagBindingHandlerName];
        }
        return options;
      };
      this.preprocessNode = function(node) {
        var nodeReplacement, replacementRequiredBindingHandlers, tagBindingHandler, tagBindingHandlerNames;
        tagBindingHandlerNames = findTagCompatibleBindingHandlerNames(node);
        if (tagBindingHandlerNames.length > 0) {
          node.tagHandlers = tagBindingHandlerNames;
          replacementRequiredBindingHandlers = _.filter(tagBindingHandlerNames, function(key) {
            var _ref;
            return ((_ref = koBindingHandlers[key].tag) != null ? _ref.replacedWith : void 0) != null;
          });
          if (replacementRequiredBindingHandlers.length > 1) {
            throw new Error("More than one binding handler specifies a replacement node for the node with name '" + node.tagName + "'.");
          }
          if (replacementRequiredBindingHandlers.length === 1) {
            tagBindingHandler = koBindingHandlers[replacementRequiredBindingHandlers[0]];
            nodeReplacement = document.createElement(tagBindingHandler.tag.replacedWith);
            mergeAllAttributes(node, nodeReplacement);
            ko.utils.replaceDomNodes(node, [nodeReplacement]);
            nodeReplacement.tagHandlers = tagBindingHandlerNames;
            nodeReplacement.originalTagName = node.tagName;
            return nodeReplacement;
          }
        }
      };
      this.nodeHasBindings = function(node, bindingContext) {
        var isCompatibleTagHandler, tagBindingHandlers;
        tagBindingHandlers = findTagCompatibleBindingHandlerNames(node);
        isCompatibleTagHandler = tagBindingHandlers.length > 0;
        return isCompatibleTagHandler || realBindingProvider.nodeHasBindings(node, bindingContext);
      };
      this.getBindings = function(node, bindingContext) {
        var existingBindings, tagBindingHandlerName, tagBindingHandlerNames, _i, _len;
        existingBindings = (realBindingProvider.getBindings(node, bindingContext)) || {};
        tagBindingHandlerNames = findTagCompatibleBindingHandlerNames(node);
        if (tagBindingHandlerNames.length > 0) {
          for (_i = 0, _len = tagBindingHandlerNames.length; _i < _len; _i++) {
            tagBindingHandlerName = tagBindingHandlerNames[_i];
            existingBindings[tagBindingHandlerName] = processOptions(node, tagBindingHandlerName, bindingContext);
          }
        }
        return existingBindings;
      };
      return this;
    };
    ko.bindingProvider.instance = new tagBindingProvider();
    bo.ViewModel = {
      extend: function(definition) {
        var key, value, viewModel;
        viewModel = function() {};
        for (key in definition) {
          if (!__hasProp.call(definition, key)) continue;
          value = definition[key];
          if (!_.isFunction(value)) {
            viewModel.prototype[key] = value;
          }
        }
        return viewModel;
      }
    };
    koBindingHandlers.part = {
      init: function(element, valueAccessor) {
        var realValueAccessor, viewModel;
        viewModel = ko.utils.unwrapObservable(valueAccessor() || {});
        realValueAccessor = function() {
          return {
            data: viewModel,
            name: viewModel.viewName
          };
        };
        return koBindingHandlers.template.init(element, realValueAccessor);
      },
      update: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var deferred, lastViewModel, realValueAccessor;
        viewModel = ko.utils.unwrapObservable(valueAccessor());
        if (!(viewModel != null)) {
          return;
        }
        realValueAccessor = function() {
          return {
            data: viewModel,
            name: viewModel.viewName
          };
        };
        lastViewModel = ko.utils.domData.get(element, '__part__lastViewModel');
        if ((lastViewModel != null) && (lastViewModel.hide != null)) {
          lastViewModel.hide();
        }
        deferred = new $.Deferred();
        if (viewModel.beforeShow != null) {
          deferred = bo.ajax.listen(function() {
            return viewModel.beforeShow();
          });
        } else {
          deferred.resolve();
        }
        return deferred.done(function() {
          koBindingHandlers.template.update(element, realValueAccessor, allBindingsAccessor, viewModel, bindingContext);
          if (viewModel.show != null) {
            viewModel.show();
          }
          return ko.utils.domData.set(element, '__part__lastViewModel', viewModel);
        });
      }
    };
    regionManagerContextKey = '$regionManager';
    bo.RegionManager = (function() {

      function RegionManager() {
        this.defaultRegion = void 0;
        this.regions = {};
      }

      RegionManager.prototype.show = function(viewModel) {
        if ((_.keys(this.regions)).length === 1) {
          return this.regions[_.keys(this.regions)[0]](viewModel);
        } else if (this.defaultRegion != null) {
          return this.regions[this.defaultRegion](viewModel);
        } else {
          throw new Error('Cannot use show when multiple regions exist');
        }
      };

      RegionManager.prototype.showAll = function(viewModels) {
        var regionKey, vm;
        for (regionKey in viewModels) {
          vm = viewModels[regionKey];
          if (this.regions[regionKey] === void 0) {
            throw new Error("This region manager does not have a '" + regionKey + "' region.");
          }
          this.regions[regionKey](vm);
        }
        return void 0;
      };

      RegionManager.prototype.register = function(name, isDefault) {
        if (isDefault) {
          this.defaultRegion = name;
        }
        return this.regions[name] = ko.observable();
      };

      RegionManager.prototype.get = function(name) {
        return this.regions[name]();
      };

      return RegionManager;

    })();
    koBindingHandlers.regionManager = {
      init: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var innerBindingContext, regionManager, regionManagerProperties;
        regionManager = ko.utils.unwrapObservable(valueAccessor());
        regionManagerProperties = {};
        regionManagerProperties[regionManagerContextKey] = regionManager;
        innerBindingContext = bindingContext.extend(regionManagerProperties);
        ko.applyBindingsToDescendants(innerBindingContext, element);
        return {
          controlsDescendantBindings: true
        };
      }
    };
    return koBindingHandlers.region = {
      tag: 'region->div',
      init: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var isDefault, regionId, regionManager;
        regionManager = bindingContext[regionManagerContextKey];
        if (regionManager === void 0) {
          throw new Error('region binding handler / tag must be a child of a regionManager');
        }
        regionId = element.id || 'main';
        isDefault = (element.getAttribute('data-default')) === 'true';
        regionManager.register(regionId, isDefault);
        return koBindingHandlers.part.init(element, (function() {
          return {};
        }), allBindingsAccessor, viewModel, bindingContext);
      },
      update: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var regionId, regionManager;
        regionManager = bindingContext[regionManagerContextKey];
        regionId = element.id || 'main';
        return koBindingHandlers.part.update(element, (function() {
          return regionManager.get(regionId);
        }), allBindingsAccessor, viewModel, bindingContext);
      }
    };
  });
})(window, document, window["jQuery"], window["ko"]);
