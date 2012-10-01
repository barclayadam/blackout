###
 blackout - v2.0.0
 Copyright (c) 2012 Adam Barclay.
 Distributed under MIT license
 http://github.com/barclayadam/blackout
###

((window, document, $, ko) ->	
	((factory) ->
		# Support three module loading scenarios
		if typeof require is "function" and typeof exports is "object" and typeof module is "object"		  
		    # [1] CommonJS/Node.js
		    factory module["exports"] or exports # module.exports is for Node.js
		else if typeof define is "function" and define["amd"]		  
		    # [2] AMD anonymous module
		    define ["exports"], factory
		else		  
		    # [3] No module loader (plain <script> tag) - put directly in global namespace
		    factory window["bo"] = {}
	)((boExports) ->
		if ko is undefined
		    throw new Error 'knockout must be included before blackout.'

	    # Declare some common variables used throughout the library
	    # to help reduce minified size.
	    koBindingHandlers = ko.bindingHandlers

		# Root namespace into which the public API will be exported.
		bo = boExports ? {}

		bo.log = 
		    enabled: false
		
		# We attempt to use console.log to determine availability
		# and safety of use, setting `console` to an empty object
		# in the instance of failure.
		try
		    window.console.log()
		catch e
		    window.console = {}
		
		
		# For the given `levels` will create a logging method
		# on the `bo.log` object to be used to log:
		#
		# * debug
		# * info
		# * warn
		# * error
		'debug info warn error'.replace /\w+/g, (n) ->
		    # The method used to alias through to the `console.log`
		    # method if available, or to fail silently if no logging
		    # mechanism is built-in to the browser.
		    #
		    # Note this does also fail in IE8/9 as the `apply` functionality
		    # is not available on the `console.[n]` functions.
		    bo.log[n] = -> 
		        if bo.log.enabled
		            (window.console[n] || window.console.log || ->).apply? window.console, arguments

		bo.utils =
		    toTitleCase: (str) ->
		        if str?
		            convertWord = (match) ->
		                # If 'word' matched is only an acronym perform no processing
		                if match.toUpperCase() is match
		                    match
		                else
		                    match = match.replace(/([a-z])([A-Z0-9])/g, (_, one, two) -> "#{one} #{two}") # insert a space between lower & upper / numbers
		                    match = match.replace(/\b([A-Z]+)([A-Z])([a-z])/, (_, one, two, three) -> "#{one} #{two}#{three}") # space before last upper in a sequence followed by lower
		                    match = match.replace(/^./, (s) -> s.toUpperCase()) # uppercase the first character
		
		            str.toString()
		                .replace(/\b[a-zA-Z0-9]+\b/g, convertWord)
		
		    toSentenceCase: (str) ->
		        if str?
		            convertWord = (match) ->
		                # If 'word' matched is only an acronym perform no processing
		                if match.toUpperCase() is match
		                    match
		                else
		                    match = match.replace(/([A-Z]{2,})([A-Z])$/g, (_, one, two) -> " #{one}#{two}") # Handle sentence ending with acronym
		                    match = match.replace(/([A-Z]{2,})([A-Z])([^$])/g, (_, one, two, three) -> " #{one} #{two.toLowerCase()}#{three}") # Separate out acronyms first
		                    match = match.replace(/([a-z])([A-Z0-9])/g, (_, one, two) -> "#{one} #{two.toLowerCase()}") # insert a space between lower & upper              
		                    match = match.replace(/^./, (s) -> s.toLowerCase()) # lowercase the first character
		                    match
		
		            str = str.toString()                
		            str = str.replace(/\b[a-zA-Z0-9]+\b/g, convertWord)
		            str = str.replace(/^./, (s) -> s.toUpperCase()) # uppercase the first character
		            str
		
		    # Given a value will convert it to an observable, using the following rules:
		    #
		    # * If `value` is already an observable (`ko.isObservable`) return it directly
		    # * If `value` is an array, return a `'ko.observableArray` initialised with the value
		    # * For all other cases (including `undefined` or `null` values) return a `ko.observable` initialised with the value
		    asObservable: (value) ->
		        if ko.isObservable value then return value
		        if _.isArray value then ko.observableArray value else ko.observable value
		EventBus = ->
		    _subscribers = {}
		    
		    clearAll = ->
		        _subscribers = {}
		 
		    # Subscribes the given function to the specified messageName, being executed
		    # if the exact same named event is raised or a `namespaced` event published
		    # with a root of the given `messageName` (e.g. publishing a message with
		    # the name `myNamespace:myEvent` will call subscribers of both 
		    # `myNamespace:myEvent` and `myNamespace`).
		    #
		    # The return result from this function is a subscription, an object that
		    # has a single 'unsubscribe' method that, if called, will dispose of the
		    # subscription to the named event meaning no further events will be published
		    # to the given function.
		    subscribe = (messageName, callback) ->
		        if _.isArray messageName
		            for message in messageName
		                subscribe message, callback
		
		            undefined
		        else
		            if _subscribers[messageName] is undefined
		                _subscribers[messageName] = {} 
		
		            newToken = _.size _subscribers[messageName]
		
		            _subscribers[messageName][newToken] = callback
		
		            # Return value for a subscription which is an object with
		            # a single `unsubscribe` method which will dispose of subscription
		            # on execution to stop any further publications from executing
		            # the specified `callback`.
		            unsubscribe: ->
		                delete _subscribers[messageName][newToken]
		
		    # Publishes the given named message to any subscribed listeners, passing 
		    # the `messageData` argument on to each subscriber as an arguments to the 
		    # subscription call.
		    #
		    # (e.g. 
		    #    subscribe "My Event", (messageData) ->
		    #    publish   "My Event", messageData
		    # )
		    publish = (messageName, args = {}) ->
		        bo.log.debug "Publishing #{messageName}", args
		
		        indexOfSeparator = -1
		        messages = [messageName]
		
		        while messageName = messageName.substring 0, messageName.lastIndexOf ':'
		            messages.push messageName 
		
		        for msg in messages
		            for t, subscriber of (_subscribers[msg] || {})
		                subscriber.call @, args
		
		        undefined
		
		    return {
		        clearAll: clearAll
		        subscribe: subscribe
		        publish: publish
		    }
		
		bo.EventBus = EventBus
		bo.bus = new bo.EventBus
		class bo.Uri
		    encode = encodeURIComponent
		    decode = decodeURIComponent
		
		    standardPorts =
		        http: 80
		        https: 443
		
		    queryStringVariable = (name, value) ->        
		        t = encode(name)
		
		        value = value.toString()
		
		        if value.length > 0
		            t += "=" + encode(value)  
		
		        t
		
		    objectToQuery = (variables) ->
		        tmp = []
		
		        for name, val of variables when val isnt null
		            if _.isArray val
		                for v in val when v isnt null
		                    tmp.push queryStringVariable name, v 
		            else
		                tmp.push queryStringVariable name, val
		
		        tmp.length and tmp.join "&"
		
		    convertToType = (value) ->
		        if not value?
		            return undefined
		
		        valueLower = value.toLowerCase()
		
		        if valueLower is 'true' or valueLower is 'false'
		            return value is 'true'
		
		        asNumber = parseFloat value
		
		        if not _.isNaN asNumber 
		            return asNumber
		
		        return value
		
		
		    queryToObject = (qs) ->
		        if not qs
		            return {}
		
		        qs = qs.replace /^[^?]*\?/, '' # Remove up to ?
		        qs = qs.replace /&$/, ''   # Remove trailing &
		        qs = qs.replace /\+/g, ' ' # Replace + with space
		
		        query = {}
		
		        for p in qs.split '&'
		            split = p.split '='
		
		            key = decode split[0] 
		            value = convertToType decode split[1] 
		
		            if query[key]
		                # Convert existing to an array
		                if not _.isArray query[key]                 
		                    query[key] = [query[key]]
		
		                query[key].push value
		
		            else
		                query[key] = value
		
		        query
		
		    constructor: (uri, options = { decode: true }) ->
		        @variables = {}
		
		        anchor = document.createElement 'a'
		        anchor.href = uri
		
		        @path = anchor.pathname
		        
		        if options.decode is true
		            @path = decode @path
		
		        if @path.charAt(0) != '/'
		            @path = "/#{@path}"
		
		        @fragment = anchor.hash?.substring(1)
		        @query = anchor.search?.substring(1)
		        @variables = queryToObject @query
		
		        if uri.charAt(0) is '/' or uri.charAt(0) is '.'
		            @isRelative = true
		        else
		            @isRelative = false
		
		            @scheme = anchor.protocol
		            @scheme = @scheme.substring 0, @scheme.length - 1
		
		            @port = parseInt anchor.port, 10
		            @host = anchor.hostname
		
		            if standardPorts[@scheme] is @port
		                @port = null
		
		    clone: () ->
		        new bo.Uri @toString()
		
		    toString: ->
		        s = ""
		        q = objectToQuery @variables
		
		        s =  @scheme + "://" if @scheme
		        s += @host           if @host
		        s += ":" + @port     if @port
		        s += @path           if @path
		        s += "?" + q         if q
		        s += "#" + @fragment if @fragment
		        s
		ajax = bo.ajax = {}
		
		# Used to store any request promises that are executed, to
		# allow the `bo.ajax.listen` function to capture the promises that
		# are executed during a function call to be able to generate a promise
		# that is resolved when all requests have completed.
		requestDetectionFrame = []
		
		class RequestBuilder
		    doCall = (httpMethod, requestBuilder) ->
		        # TODO: Extract extension of deferred to give non-failure
		        # handling semantics that could be used elsewhere.
		        getDeferred = $.Deferred()
		        failureHandlerRegistered = false
		
		        requestOptions = _.defaults requestBuilder.properties,
		            url: requestBuilder.url
		            type: httpMethod
		
		        ajaxRequest = $.ajax requestOptions
		
		        bo.bus.publish "ajaxRequestSent:#{requestBuilder.url}", 
		            path: requestBuilder.url
		            method: httpMethod
		
		        ajaxRequest.done (response) ->
		            bo.bus.publish "ajaxResponseReceived:success:#{requestBuilder.url}", 
		                path: requestBuilder.url
		                method: httpMethod
		                response: response
		                status: 200
		
		            getDeferred.resolve response
		
		        ajaxRequest.fail (response) ->
		            failureMessage =
		                path: requestBuilder.url
		                method: httpMethod
		                responseText: response.responseText
		                status: response.status
		
		            bo.bus.publish "ajaxResponseReceived:failure:#{requestBuilder.url}", failureMessage
		
		            if not failureHandlerRegistered
		                bo.bus.publish "ajaxResponseFailureUnhandled:#{requestBuilder.url}", failureMessage
		
		            getDeferred.reject response
		
		        promise = getDeferred.promise()
		
		        promise.fail = (callback) ->
		            failureHandlerRegistered = true
		
		            getDeferred.fail callback
		
		        requestDetectionFrame.push promise
		
		        promise
		
		    constructor: (@url) ->
		        @properties = {}
		
		    get: () ->
		        doCall 'GET', @
		
		    post: () ->
		        doCall 'POST', @
		
		    put: () ->
		        doCall 'PUT', @
		
		    delete: () ->
		        doCall 'DELETE', @
		
		    head: () ->
		        doCall 'HEAD', @
		
		# Entry point to the AJAX API, which begins the process
		# of 'building' a call to a server using an AJAX call. This
		# method returns a `request builder` that has a number of methods
		# on it that allows further setting of data, such as query
		# strings (if not already supplied), form data and content types.
		#
		# The AJAX API is designed to provide a simple method of entry to
		# creating AJAX calls, to allow composition of calls if necessary (by
		# passing the request builder around), and to provide the familiar semantics
		# of publishing events as used extensively throughout `boson`.
		ajax.url = (url) ->
		    new RequestBuilder url
		
		# Provides a way of listening to all AJAX requests during the execution
		# of a method and executing a callback based on the result of all those
		# captured requests.
		#
		# In the case where multiple requests are executed the method returns the 
		# `promise` that tracks the aggregate state of all requests. The method will 
		# resolve this `promise` as soon as all the requests resolve, or reject the 
		# `promise` as one of the requests is rejected. 
		#
		# If all requests are successful (resolved), the `done` / `then` callbacks will
		# be resolved with the values of all the requests, in the order they were
		# executed.
		#
		# In the case of multiple requests where one of the requests fails, the failure
		# callbacks of the returned `promise` will be immediately executed. This means
		# that some of the AJAX requests may still be 'in-flight' at the time of
		# failure execution.
		ajax.listen = (f) ->
		    requestDetectionFrame = []
		
		    f()
		
		    $.when.apply(@, requestDetectionFrame)
		# Creates observable extenders for both `local` and `session` storage.
		#
		# The storage extenders handle the conversion from and to a string for
		# any data type stored (including object literals), as the underlying
		# storage mechanism (as defined by the `HTML5` spec) does not perform
		# storage of any 'complex' data type.
		"local session".replace /\w+/g, (type) ->
		    ko.extenders[type + 'Storage'] = (target, key) ->          
		        stored = window[type + 'Storage'].getItem key
		
		        if stored?
		            target (JSON.parse stored).value
		
		        target.subscribe (newValue) ->
		            window[type + 'Storage'].setItem key, JSON.stringify { value: newValue }
		
		        target
		notifications = bo.notifications = {}
		
		# Namespace that provides a number of methods for publishing notifications, 
		# messages that the system can listen to to provide feedback to the user
		# in a consistent fashion.
		#
		# All messages that are published are within the `notification` namespace, with
		# the second level name being the level of notification (e.g. `notification:success`).
		# The data that is passed as arguments contains:
		# * `text`: The text of the notification
		# * `level`: The level of the notification (i.e. `success`, `warning` or `error`)
		'success warning error'.replace /\w+/g, (level) ->
		    notifications[level] = (text) ->
		        bo.bus.publish "notification:#{level}", 
		            text: text
		            level: level
		templating = bo.templating = {}
		
		# A `template source` that will use the `bo.templating.templates` object
		# as storage of a named template.
		class StringTemplateSource
		    constructor: (@templateName) ->
		
		    text: (value) ->
		        ko.utils.unwrapObservable templating.templates[@templateName]
		
		class ExternalTemplateSource
		    constructor: (@templateName) ->
		        @stringTemplateSource = new StringTemplateSource @templateName
		
		    text: (value) ->
		        if templating.templates[@templateName] is undefined
		            template = ko.observable templating.loadingTemplate
		            templating.set @templateName, template
		
		            loadingPromise = templating.loadExternalTemplate @templateName
		
		            loadingPromise.done template
		
		        @stringTemplateSource.text.apply @stringTemplateSource, arguments
		
		# Creates the custom `boson` templating engine by augmenting the given templating
		# engine with a new `makeTemplateSource` function that first sees if
		# a template has been added via. `bo.templating.add` and returns a
		# `StringTemplateSource` if found, attempts to create an external
		# template source (see `bo.templating.isExternal`) or falls back 
		# to the original method if not.
		createCustomEngine = (templateEngine) ->
		    originalMakeTemplateSource = templateEngine.makeTemplateSource
		
		    templateEngine.makeTemplateSource = (template) ->
		        if templating.templates[template]?
		            new StringTemplateSource template
		        else if templating.isExternal template
		            new ExternalTemplateSource template
		        else
		            originalMakeTemplateSource template
		
		    templateEngine
		
		ko.setTemplateEngine createCustomEngine new ko.nativeTemplateEngine()
		
		# The public API of the custom templating support built on-top of the
		# native `knockout` templating engine, providing support for string and
		# external templates.
		#
		# String templates are used most often throughout this library to add
		# templates used by the various UI elements, although could be used by
		# clients of this library to add small templates through script (for
		# most needs external templates or those already defined via a standard
		# method available from `knockout` is the recommended approach).
		#
		# External templates are templates that are loaded from an external source,
		# and would typically be served up by the same server that delivered the initial 
		# application.
		
		# The template that is to be used when loading an external template,
		# set immediately whenever an external template that has not yet been
		# loaded is used and bound to, automatically being replaced once the
		# template has been successfully loaded.
		templating.loadingTemplate = 'Loading...'
		
		# Determines whether the specified template definition is 'external',
		# whether given the specified name a template could be loaded by passing
		# it to the `bo.templating.loadExternalTemplate` method.
		#
		# By default a template is deemed to be external if it being with the
		# preifx `e:` (e.g. `e:My External Template`). When a template is
		# identified as external it will be passed to the `bo.templating.loadExternalTemplate`
		# method to load the template from the server.
		templating.isExternal = (name) ->
		    name.indexOf && name.indexOf 'e:' is 0
		
		# The location from which to load external templates, with a `{name}`
		# token indicating the location into which to inject the name of the
		# template being added.
		#
		# For example, given an `externalPath` of `/Templates/{name}` and a template
		# name of `e:Contact Us` the template will be loaded from `/Templates/Contact Us`.
		#
		# This property is used from the default implementation of
		# `bo.templating.loadExternalTemplate`, which can be completely overriden
		# if this simple case does not suffice for a given project.
		templating.externalPath = '/Templates/Get/{name}'
		
		templating.loadExternalTemplate = (name) ->
		    # The default support is for template names beginning 'e:', strip
		    # that identifier out.
		    name = name.substring 2
		
		    path = templating.externalPath.replace '{name}', name
		
		    bo.ajax.url(path).get()
		
		# Resets the templating support by removing all data and templates
		# that have been previously added.
		templating.reset = ->
		    templating.templates = { _data: {} }
		
		# Sets a named template, which may be an observable value, making that
		# named template available throughout the application using the standard
		# knockout 'template' binding handler.
		#
		# If the value is an observable, when using that template it will be
		# automatically re-rendered when the value of the observable changes.
		#
		# * `name`: The name of the template to add.
		# * `template`: The string value (may be an `observable`) to set as the
		#   contents of the template.
		templating.set = (name, template) ->
		    if ko.isWriteableObservable templating.templates[name]
		        templating.templates[name] template
		    else
		        templating.templates[name] = template
		
		templating.reset()
		validation = bo.validation = {}
		
		getMessageCreator = (propertyRules, ruleName) ->
		    propertyRules["#{ruleName}Message"] or
		        bo.validation.rules[ruleName].message or
		        "The field is invalid" 
		
		# A function that is given a chance to format an error message
		# that has been generated for any validation failures. This
		# is provided to allow calling formatters such as `toSentenceCase`
		# to produce better default messages.
		#
		# This function will take a single `string` parameter and should
		# return a `string` to use as the error message.
		validation.formatErrorMessage = (msg) -> msg
		
		getErrors = (observableValue) ->    
		    errors = []
		    rules = observableValue.validationRules
		
		    # We only peek at the actual observable values as all subscriptions
		    # are done manually in a validatable property's validate method, yet
		    # this could be called as part of the model's validate method which
		    # creates a computed around the whole model, causing multiple subscriptions.
		    value = observableValue.peek()
		
		    for ruleName, ruleOptions of rules 
		        rule = bo.validation.rules[ruleName]
		
		        if rule?
		            isValid = rule.validator value, ruleOptions
		
		            if not isValid
		                msgCreator = getMessageCreator rules, ruleName
		
		                if _.isFunction msgCreator
		                    errors.push validation.formatErrorMessage msgCreator ruleOptions
		                else 
		                    errors.push validation.formatErrorMessage msgCreator
		
		    errors
		
		# Validates the specified 'model'.
		#
		# If the model has `validationRules` defined (e.g. a `validatable` observable) 
		# will validate those values.
		validateModel = (model) -> 
		    valid = true  
		
		    if model?
		        # We have reached a property that has been marked as `validatable`
		        if model.validate? and model.validationRules?
		            model.validate()
		            valid = model.isValid() && valid
		          
		        # Need to ensure that children are also validated, either
		        # child properties (this is a 'model'), or an array (which
		        # may also have its own validation rules).
		        if ko.isObservable model 
		            unwrapped = model.peek() 
		        else 
		            unwrapped = model
		
		        if _.isObject unwrapped
		            for own propName, propValue of unwrapped
		                valid = (validateModel propValue) && valid
		
		        if _.isArray unwrapped
		            for item in unwrapped
		                validateModel item
		
		    valid
		
		# Exposed as `bo.validation.mixin`
		#
		# Given a model will make it 'validatable', such that a call to
		# the mixed-in `validate` method will validate the model and its
		# children (properties) against a defined set of rules, rules that
		# are defined at an observable property level using the `validated`
		# observable extender.
		#
		# When a model is validated all child properties and arrays will be 
		# navigated to check for validation rules, both observable and
		# non-observable values, although only observable properties will
		# have validation rules specified against them.
		validation.mixin = (model) ->
		    # Validates this model against the currently-defined set of
		    # rules (against the child properties), setting up dependencies
		    # on all propertes of this model to update the set of errors
		    # and `isValid` state should any property change.
		    #
		    # The model of executing `validate` only once to set-up the
		    # dependencies is to allow filling in a form completely
		    # before checking validity to avoid errors being shown
		    # immediately, but then allowing any errors detected to be removed
		    # on property change immediately instead of having to attempt
		    # a resubmit and a validate.
		    model.validate = ->    
		        # Only create a computed once, which will then keep
		        # the `isValid` property up-to date whenever a value
		        # of this model and its children changes.
		        if not model.validated()
		            ko.computed ->
		                model.isValid validateModel model
		
		            model.validated true
		
		        # Whenever a model is explicitly validated the server errors
		        # of the model will be reset, as it would not be possible to
		        # determine validity of the model until going back to the server.
		        model.serverErrors []
		
		    # An observable that indicates whether this model has been validated,
		    # set to `true` when the `validate` method of this method has been 
		    # called at least once.
		    model.validated = ko.observable false
		
		    # An observable that indicates whether or not this model is
		    # considered 'valid' on the client side, which is defined as having no
		    # `client-side` validation errors.
		    #
		    # A model may have `serverErrors` that, as they can only be
		    # checked server-side, are not considered when dealing with
		    # the validitiy of a model as this value is used when determining
		    # whether to even submit a form / command for processing by the
		    # server.
		    model.isValid = ko.observable()
		
		    # An observable that will contain an array of error messages
		    # that apply to the model as a whole but are not considered when
		    # determining the `isValid` state of this form (e.g. it would not
		    # stop the posting of a form to the server).
		    model.serverErrors = ko.observable []
		
		    # Sets any server validation errors, errors that could not be checked client
		    # side but mean the action attempted failed. These server errors are not considered
		    # when determining the `isValid` state of a form, but are instead for
		    # informational purposes.
		    #
		    # The `errors` argument is an object that contains property name to server errors
		    # mappings, with all unknown property errors being flattened into a single
		    # list within this model.
		    model.setServerErrors = (errors) ->
		        for own key, value of model
		            if value?.serverErrors?
		                value.serverErrors _.flatten [errors[key]] || []
		                delete errors[key]
		
		        model.serverErrors _.flatten _.values errors
		
		validation.newModel = (model = {}) ->
		    validation.mixin model
		
		    model
		
		# Defines the set of validation rules that this observable must follow
		# to be considered `valid`.
		#
		# The observable will be extended with:
		#  * `errors` -> An observable that will contain an array of the errors of the observable
		#  * `isValid` -> An observable value that identifies the value of the observable as valid
		#                 according to its errors
		#  * `validationRules` -> The rules passed as the options of this extender, used in the validation
		#                         of this observable property.
		ko.extenders.validationRules = (target, validationRules = {}) ->
		    target.validationRules = validationRules
		    
		    # Validates this property against the currently-defined set of
		    # rules (against the child properties), setting up a dependency
		    # that will update the `errors` and `isValid` property of this
		    # observable on any value change.
		    target.validate = ->
		        target.validated true
		
		    # An observable that indicates whether this property has been validated,
		    # set to `true` when the `validate` method of this method has been 
		    # called at least once.
		    target.validated = ko.observable false
		
		    target.errors = ko.observable []
		    target.isValid = ko.observable true
		
		    # An observable that will contain an array of error messages
		    # that apply to this property but are not considered when
		    # determining the `isValid` state of this property (e.g. it would not
		    # stop the posting of a form to the server).
		    target.serverErrors = ko.observable []
		
		    validate = ->
		        target.serverErrors []
		
		        target.errors getErrors target
		        target.isValid target.errors().length is 0
		
		    # When this value is changed the server errors will be removed, as
		    # there would be no way to identify whether they were still accurate
		    # or not until re-submitted, so for user-experience purposes these
		    # errors are removed when a user modifies the value.
		    target.subscribe ->
		        validate()
		
		    validate()
		
		    target
		
		ko.subscribable.fn.addValidationRules = (validationRules) ->
		    ko.extenders.validationRules @, validationRules
		hasValue = (value) ->
		    value? and (not value.replace or value.replace(/[ ]/g, '') isnt '')
		
		emptyValue = (value) ->
		    not hasValue value
		
		parseDate = (value) ->
		    if _.isDate value
		        value
		
		withoutTime = (dateTime) ->
		    if dateTime?
		        new Date dateTime.getYear(), dateTime.getMonth(), dateTime.getDate()
		
		today = () ->
		    withoutTime new Date()
		
		labels = document.getElementsByTagName 'label'
		
		getLabelFor = (element) ->
		    _.find labels, (l) ->
		        l.getAttribute('for') is element.id
		
		rules =
		    required: 
		        validator: (value, options) ->
		            hasValue value
		        
		        message: "This field is required"
		
		        modifyElement: (element, options) ->                
		            element.setAttribute "aria-required", "true"
		            element.setAttribute "required", "required"
		            
		            label = getLabelFor element
		
		            if label
		                ko.utils.toggleDomNodeCssClass element, 'required', true
		
		    regex:
		        validator: (value, options) ->
		            (emptyValue value) or (options.test value)
		
		        message: "This field is invalid"
		
		        modifyElement: (element, options) ->                
		            element.setAttribute "pattern", "" + options
		
		    numeric:
		        validator: (value, options) ->
		            (emptyValue value) or (isFinite value)
		
		        message: (options) ->
		            "This field must be numeric"
		
		        modifyElement: (element, options) ->                
		            element.setAttribute "type", 'numeric'   
		
		    integer:
		        validator: (value, options) ->
		            (emptyValue value) or (/^[0-9]+$/.test value)
		
		        message: "This field must be a whole number"
		
		        modifyElement: (element, options) ->                
		            element.setAttribute "type", 'numeric'           
		
		    exactLength: 
		        validator: (value, options) ->
		            (emptyValue value) or (value.length? and value.length == options)
		
		        message: (options) ->
		            "This field must be exactly #{options} characters long"
		
		        modifyElement: (element, options) ->        
		            element.setAttribute "maxLength", options
		
		    minLength: 
		        validator: (value, options) ->
		            (emptyValue value) or (value.length? and value.length >= options)
		
		        message: (options) ->
		            "This field must be at least #{options} characters long"
		    
		    maxLength:
		        validator: (value, options) ->
		            (emptyValue value) or (value.length? and value.length <= options)
		    
		        message: (options) ->
		            "This field must be no more than #{options} characters long"
		
		        modifyElement: (element, options) ->                
		            element.setAttribute "maxLength", options
		    
		    rangeLength:
		        validator: (value, options) ->
		            (rules.minLength.validator value, options[0]) and (rules.maxLength.validator value, options[1])
		    
		        message: (options) ->
		            "This field must be between #{options[0]} and #{options[1]} characters long"
		
		        modifyElement: (element, options) ->
		            element.setAttribute "maxLength", "" + options[1]
		
		    min:
		        validator: (value, options) ->
		            (emptyValue value) or (value >= options)
		
		        message: (options) ->
		            "This field must be equal to or greater than #{options}"
		
		        modifyElement: (element, options) ->                
		            element.setAttribute "min", options             
		            element.setAttribute "aria-valuemin", options
		
		    moreThan:
		        validator: (value, options) ->
		            (emptyValue value) or (value > options)
		
		        message: (options) ->
		            "This field must be greater than #{options}."
		
		    max:
		        validator: (value, options) ->
		            (emptyValue value) or (value <= options)
		
		        message: (options) ->
		            "This field must be equal to or less than #{options}"
		
		        modifyElement: (element, options) ->                
		            element.setAttribute "max", options             
		            element.setAttribute "aria-valuemax", options
		
		    lessThan:
		        validator: (value, options) ->
		            (emptyValue value) or (value < options)
		
		        message: (options) ->
		            "This field must be less than #{options}."
		
		    range:
		        validator: (value, options) ->
		            (rules.min.validator value, options[0]) and (rules.max.validator value, options[1])
		
		        message: (options) ->
		            "This field must be between #{options[0]} and #{options[1]}"
		
		        modifyElement: (element, options) -> 
		            rules.min.modifyElement element, options[0]   
		            rules.max.modifyElement element, options[1]            
		
		    maxDate:
		        validator: (value, options) ->
		            (emptyValue value) or (parseDate(value) <=  parseDate(options))
		
		        message: (options) ->
		            "This field must be on or before #{options[0]}"
		
		    minDate:
		        validator: (value, options) ->
		            (emptyValue value) or (parseDate(value) >= parseDate(options))
		
		        message: (options) ->
		            "This field must be on or after #{options[0]}"
		
		    inFuture:
		        validator: (value, options) ->
		            if options is "Date"
		                (emptyValue value) or (withoutTime(parseDate(value)) > today())
		            else
		                (emptyValue value) or (parseDate(value) > new Date())
		
		        message: "This field must be in the future"
		
		    inPast:
		        validator: (value, options) ->
		            if options is "Date"
		                (emptyValue value) or (withoutTime(parseDate(value)) < today())
		            else
		                (emptyValue value) or (parseDate(value) < new Date())
		
		        message: "This field must be in the past"
		
		    notInPast:
		        validator: (value, options) ->
		            if options is "Date"
		                (emptyValue value) or (withoutTime(parseDate(value)) >= today())
		            else
		                (emptyValue value) or (parseDate(value) >= new Date())
		
		        message: "This field must not be in the past"
		
		    notInFuture:
		        validator: (value, options) ->
		            if options is "Date"
		                (emptyValue value) or (withoutTime(parseDate(value)) <= today())
		            else
		                (emptyValue value) or (parseDate(value) <= new Date())
		
		        message: "This field must not be in the future"
		
		    requiredIf:
		        validator: (value, options) ->
		            if options.equalsOneOf is undefined
		                throw new Error "You need to provide a list of items to check against."
		
		            if options.value is undefined
		                throw new Error "You need to provide a value."
		
		            valueToCheckAgainst = (ko.utils.unwrapObservable options.value) || null
		
		            valueToCheckAgainstInList = _.any options.equalsOneOf, (v) -> (v || null) is valueToCheckAgainst
		
		            if valueToCheckAgainstInList
		                hasValue value
		            else
		                true
		
		        message: "This field is required"
		
		    requiredIfNot:
		        validator: (value, options) ->
		            if options.equalsOneOf is undefined
		                throw new Error "You need to provide a list of items to check against."
		
		            if options.value is undefined
		                throw new Error "You need to provide a value."
		
		            valueToCheckAgainst = (ko.utils.unwrapObservable options.value) || null
		
		            valueToCheckAgainstNotInList = _.all options.equalsOneOf, (v) -> (v || null) isnt valueToCheckAgainst
		
		            if valueToCheckAgainstNotInList
		                hasValue value
		            else
		                true
		
		        message: "This field is required"
		
		    equalTo:
		        validator: (value, options) ->
		            (emptyValue value) or (value is ko.utils.unwrapObservable options)
		
		        message: (options) ->
		            "This field must be equal to #{options}."
		
		    custom:
		        validator: (value, options) ->
		            if !_.isFunction options 
		                throw new Error "Must pass a function to the 'custom' validator"
		
		            options value
		
		        message: "This field is invalid."
		
		defineRegexValidator = (name, regex) ->
		    rules[name] =
		        validator: (value, options) ->
		            rules.regex.validator value, regex
		
		        message: "This field is an invalid #{name}"
		
		        modifyElement: (element, options) ->                
		            rules.regex.modifyElement element, regex
		
		defineRegexValidator 'email', /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/i
		defineRegexValidator 'postcode', /(GIR ?0AA)|((([A-Z][0-9]{1,2})|(([A-Z][A-HJ-Y][0-9]{1,2})|(([A-Z][0-9][A-Z])|([A-Z][A-HJ-Y][0-9]?[A-Z])))) ?[0-9][A-Z]{2})/i
		
		bo.validation.rules = rules
		toOrderDirection = (order) ->
		    if order is undefined or order is 'asc' or order is 'ascending'
		        'ascending'
		    else 
		        'descending'
		
		# A DataSource is a representation of an array of data (of any kind) that
		# is represented in a consistent manner, providing functionality such as
		# server and client-side paging and sorting over the top of a `data provider`,
		# a method of loading said data (e.g. directly providing an array, using a
		# `query` to load data or any operation that can provide an array of data).
		#
		# #Paging#
		#
		# The data source supports client and server side paging, with the ability to
		# have both enabled within a single source of data which can be useful to
		# provide a small paging size for display purposes yet a larger server-side
		# page to allow fewer calls back to the server to be made.
		#
		# If paging is enabled then the `pageNumber`, `pageSize`, `pages` and `pageItems` 
		# observable properties becomes important, as they represent the (client-side)
		# page (1-based) currently being represented by the `pageItems` observable, the
		# size of the client-side page and an observable array of pages, an object with
		# `pageNumber` and `isSelected` properties, in addition to a `select` method to
		# select the represented page.
		#
		# ##Client-Side Paging##
		#
		# To enable client-side paging the `clientPaging` option must be provided in
		# the `options` at construction time, specifying the size of the page. Once this
		# option has been enabled `pageItems` will be the items to display for the
		# current (see `pageNumber`) page.
		#
		# ##Server-Side Paging##
		#
		# To enable server-side paging the `serverPaging` option must be provided in 
		# the `options` at construction time, specifying the size of the page. In addition
		# the `provider` must correctly adhere to the page size and number passed to it as 
		# the `pageSize` and `pageNumber` properties of its `loadOptions` parameter.
		#
		# When server-side paging is enabled the server must handle, if specified by the
		# options of the `DataSource`:
		#
		# * Paging
		# * Sorting
		# * Filtering
		# * Grouping
		class bo.DataSource
		    constructor: (@options) ->
		        # An observable property that represents whether or not this data source is
		        # currently loading some data (using the specified `provider`).
		        @isLoading = ko.observable false
		
		        @_hasLoadedOnce = false
		        @_serverPagingEnabled = @options.serverPaging > 0
		        @_clientPagingEnabled = @options.clientPaging > 0
		
		        @pagingEnabled = @_serverPagingEnabled or @_clientPagingEnabled
		
		        # Stores the items as loaded (e.g. without sorting / paging applied
		        # when in client-side only mode).
		        @_loadedItems = ko.observableArray()
		
		        @_sortByAsString = ko.observable()
		        @_sortByDetails = ko.observable()
		
		        # When new sorting order given will create the string representation
		        # of that sorting order in a normalised fashion (e.g. always use
		        # `ascending` or `descending` instead of `asc` or `desc`).
		        @_sortByDetails.subscribe (newValue) =>
		            normalised = _.reduce newValue, ((memo, o) -> 
		                    prop = "#{o.name} #{toOrderDirection(o.order)}"
		
		                    if memo 
		                        "#{memo}, #{prop}" 
		                    else 
		                        prop
		                ), ''
		
		            @_sortByAsString normalised
		
		        # The sorting order of this `DataSource`, a textual
		        # description of the properties by which the data is sorted.
		        #
		        # This value, when populated, will be a comma-delimited string
		        # with each value being the name of the property being sorted
		        # followed by the order (`ascending` or `descending`):
		        #
		        # `property1 ascending[, property2 descending]` 
		        @sortBy = ko.computed
		            read: @_sortByAsString
		
		            write: (value) =>
		                # TODO: Allow setting an object
		                properties = _(value.split(',')).map (p) ->
		                    p = ko.utils.stringTrim p
		
		                    indexOfSpace = p.indexOf ' '
		
		                    if indexOfSpace > -1
		                        name: p.substring 0, indexOfSpace
		                        order: toOrderDirection p.substring indexOfSpace + 1
		                    else
		                        name: p
		                        order: 'ascending'
		
		                @_sortByDetails properties
		
		        # The items that have been loaded, presented sorted, filtered and
		        # grouped as determined by the options passed to this `DataSource`.
		        @items = ko.computed =>
		            if @_sortByDetails()? and not @_serverPagingEnabled
		                @_loadedItems().sort (a, b) => 
		                    for p in @_sortByDetails()
		                        if a[p.name] > b[p.name]
		                            return if p.order is 'ascending' then 1 else -1
		                        
		                        if a[p.name] < b[p.name]
		                            return if p.order is 'ascending' then -1 else 1
		
		                    0
		            else
		                @_loadedItems()
		
		        if @options.searchParameters?
		            @searchParameters = ko.computed -> 
		                ko.toJS options.searchParameters
		
		            @searchParameters.subscribe =>
		                if @_hasLoadedOnce
		                    @load()
		        else
		            @searchParameters = ko.observable {}
		
		        @_setupPaging()
		        @_setupInitialData()
		
		    getPropertySortOrder: (propertyName) ->
		        sortedBy = @_sortByDetails()
		
		        if sortedBy? and sortedBy.length > 0
		            ordering = _.find sortedBy, (o) -> o.name is propertyName            
		            ordering?.order    
		
		    # Removes the given item from this data source.
		    #
		    # TODO: Define this method in such a way that it will handle server paging
		    # better (currently leaves a 'gap', will reshow this item if user visits another
		    # page then goes back to the page this item is on).
		    remove: (item) ->
		        @_loadedItems.remove item
		
		    # Performs a load of this data source, which will set the pageNumber to 1
		    # and then, using the `provider` specified on construction, load the
		    # items uing the current search parameters (if any), the page size (if `serverPaging`
		    # is enabled), the current order, and the page number (i.e. 1).
		    load: ->
		        currentPageNumber = @pageNumber()
		
		        @pageNumber 1
		
		        # serverPaging enabled means subscription to
		        # pageNumber to perform re-load so only execute
		        # immediately if not enabled, or if current page number
		        # is 1 as then subscription not called.
		        if not @_serverPagingEnabled or currentPageNumber is 1
		            @_doLoad()
		
		    # Goes to the specified page number.
		    goTo: (pageNumber) ->
		        @pageNumber pageNumber
		
		    # Goes to the first page, assuming that either client or server-side paging
		    # has been enabled.
		    goToFirstPage: ->
		        @goTo 1
		
		    # Goes to the last page, assuming that either client or server-side paging
		    # has been enabled.
		    goToLastPage: ->
		        @goTo @pageCount()
		
		    # Goes to the next page, assuming that either client or server-side paging
		    # has been enabled at the current page is not the last one (in which case
		    # no changes will be made).
		    goToNextPage: ->
		        if not @isLastPage()
		            @goTo @pageNumber() + 1
		
		    # Goes to the previous page, assuming that either client or server-side paging
		    # has been enabled at the current page is not the first one (in which case
		    # no changes will be made).
		    goToPreviousPage: ->
		        if not @isFirstPage()
		            @goTo @pageNumber() - 1
		
		    _setupInitialData: ->
		        if @options.provider? and _.isArray @options.provider
		            @_setData @options.provider
		            @goTo 1
		
		        if @options.initialSortOrder?
		            @sortBy @options.initialSortOrder
		
		        if @options.autoLoad is true
		            @load()
		
		    _setupPaging: ->
		        @_lastProviderOptions = -1
		        @clientPagesPerServerPage = @options.serverPaging / (@options.clientPaging || @options.serverPaging)
		
		        @pageSize = ko.observable()
		        @totalCount = ko.observable(0)
		        @pageNumber = ko.observable().extend
		            publishable: { message: ((p) -> "pageChanged:#{p()}"), bus: @ }
		
		        # The observable typically bound to in the UI, representing the
		        # current `page` of items, which if paging is specified will be the
		        # current page as defined by the `pageNumber` observable, or if
		        # no paging options have been supplied the loaded items.
		        @pageItems = ko.computed =>
		            if @_clientPagingEnabled and @_serverPagingEnabled
		                start = ((@pageNumber() - 1) % @clientPagesPerServerPage) * @pageSize()
		                end = start + @pageSize()
		                @items().slice start, end
		            else if @_clientPagingEnabled
		                start = (@pageNumber() - 1) * @pageSize()
		                end = start + @pageSize()
		                @items().slice start, end
		            else
		                @items()
		
		        # An observable property that indicates the number of pages that
		        # exist within this data source.
		        @pageCount = ko.computed =>
		            if @totalCount()
		                Math.ceil @totalCount() / @pageSize()
		            else 
		                0
		
		        # An observable property that indicates whether the current page 
		        # is the first one.
		        @isFirstPage = ko.computed =>
		            @pageNumber() is 1
		
		        # An observable property that indicates whether the current page 
		        # is the last one.
		        @isLastPage = ko.computed =>
		            @pageNumber() is @pageCount() or @pageCount() is 0
		                
		        # Server paging means any operation that would affect the
		        # items loaded and currently displayed must result in a load.
		        if @options.serverPaging
		            @pageNumber.subscribe =>
		                @_doLoad()
		
		            @sortBy.subscribe =>
		                @_doLoad()
		    
		    _doLoad: ->
		        if _.isArray @options.provider
		            return
		
		        loadOptions = _.extend {}, @searchParameters()
		
		        if @_serverPagingEnabled
		            loadOptions.pageSize = @options.serverPaging
		            loadOptions.pageNumber = Math.ceil @pageNumber() / @clientPagesPerServerPage
		        
		        if @sortBy()?
		            loadOptions.orderBy = @sortBy()
		
		        if _.isEqual loadOptions, @_lastProviderOptions
		            return
		
		        @isLoading true
		
		        @options.provider loadOptions, ((loadedData) =>
		            @_setData loadedData
		            @_lastProviderOptions = loadOptions
		
		            @isLoading false
		        ), @
		
		    _setData: (loadedData) ->   
		        items = []
		
		        if @options.serverPaging
		            items = loadedData.items
		
		            @pageSize @options.clientPaging || @options.serverPaging
		            @totalCount loadedData.totalCount || loadedData.totalItems || 0
		        else
		            items = loadedData
		
		            @pageSize @options.clientPaging || loadedData.length
		            @totalCount loadedData.length
		
		        if @options.map?
		            items = _.chain(items).map(@options.map).compact().value()
		
		        @_loadedItems items
		        @_hasLoadedOnce = true
		    
		location = bo.location = {}
		
		windowHistory = window.history
		windowLocation = window.location
		
		# Cached regex for cleaning leading hashes and slashes.
		routeStripper = /^[#\/]/
		hasPushState  = !!(windowHistory && windowHistory.pushState)
		
		# Gets the true hash value. Cannot use location.hash directly due to bug
		# in Firefox where location.hash will always be decoded.
		_getHash = () ->
		    match = windowLocation.href.match(/#(.*)$/)
		    if match then match[1] else ""
		
		# Get the cross-browser normalized URL fragment, either from the URL or
		# the hash.
		_getFragment = () ->
		    if hasPushState
		        fragment = windowLocation.pathname
		        fragment += windowLocation.search || ''
		    else
		        fragment = _getHash()
		
		    fragment.replace routeStripper, ""
		
		    fragment = fragment.replace /\/\//g, '/'
		
		    if fragment.charAt(0) isnt '/'
		        fragment = "/#{fragment}"
		
		    fragment
		
		    decodeURI fragment 
		
		# ## History Management
		#
		# The history management APIs provide a higher-level abstraction of
		# history and URL manipulation than the low-level `pushState` and
		# `replaceState`.
		#
		# The history manager will handle the updating of the URL, publishing
		# of URL change messages, and managing variables which may be set as
		# query string parameters for allowing the application to be
		# bookmarkable.
		
		uri = location.uri = ko.observable()
		
		updateUri = ->
		    location.uri new bo.Uri document.location.toString()
		
		updateUri()
		
		location.host = ->
		    uri().host
		
		location.path = ko.computed -> uri().path
		
		location.fragment = ko.computed -> uri().fragment || ''
		
		location.query = ko.computed -> uri().query
		
		location.variables = ko.computed -> uri().variables
		
		# routeVariables represents the current route variables, which may not
		# represent the current URL's `variables` property as this uses
		# whatever browser mechanism is available to update these values, which
		# in non `pushState` browsers means the query is actually part of the
		# hash (e.g. `bo.location.routePath` is used to construct the
		# variables)
		location.routeVariables = ko.computed
		    read: ->
		        # We are dependent on the current URI
		        uri()
		
		        new bo.Uri(_getFragment()).variables
		
		    deferEvaluation: true
		
		location.routeVariables.set = (key, value, options) ->
		    currentUri = new bo.Uri location.routePath()
		    currentUri.variables[key] = value
		
		    location.routePath currentUri.toString(), 
		        replace: options.history is false
		
		# Provides an abstraction of the path of the URI to handle the difference
		# between pushState and non-pushState browsers. This is the observable that
		# routing uses to manage the URL, the one that represents the 'path' the
		# user is at, regardless of what the actual URL is (it will read the fragment
		# when the browser does not support push-state).
		location.routePath = ko.computed
		    read: ->
		        # We are dependent on the current URI
		        uri()
		        
		        new bo.Uri(_getFragment()).path
		
		    # Goes to the specified path, which will typically have been created using
		    # the routing system, although that is not a requirement.
		    #
		    # Will push a new history entry (`windowHistory.pushState`) and publish
		    # a `urlChanged:internal` message with the new URL & route path and `external` 
		    # set to `false`.
		    write: (newPath, options = {}) ->
		        # Not actually changing anything
		        if location.routePath() is newPath
		            return false
		
		        if options.replace is true
		            windowHistory.replaceState null, document.title, newPath
		        else
		            windowHistory.pushState null, document.title, newPath
		
		        updateUri()
		
		        bo.bus.publish 'urlChanged:internal', 
		            url: _getFragment()
		            path: location.routePath()
		            variables: location.routeVariables()
		            external: false
		
		# Testing purposes only
		location.reset = ->
		    updateUri()
		
		# Bind to the popstate event, as polyfilled previously, and convert
		# it into a message that is published on the bus for others to
		# listen to.
		ko.utils.registerEventHandler window, 'popstate', ->
		    updateUri()
		
		    bo.bus.publish 'urlChanged:external', 
		        url: _getFragment()
		        path: location.routePath()
		        variables: location.routeVariables()
		        external: true
		
		# pushState & replaceState polyfill
		if not hasPushState
		    currentFragment = undefined
		
		    # If a native popstate would not have been fired then polyfill
		    # by triggering a `popstate` event on the `window`.
		    if not hasPushState and window.onhashchange isnt undefined
		        ko.utils.registerEventHandler window, 'hashchange',  ->
		            current = _getFragment()
		      
		            if current isnt currentFragment
		                if not hasPushState
		                    ko.utils.triggerEvent window, 'popstate'
		
		                currentFragment = current
		
		    windowHistory.pushState = (_, title, frag) ->
		        windowLocation.hash = frag
		        document.title = title
		
		        updateUri()
		
		    windowHistory.replaceState = (_, title, frag) ->
		        windowLocation.replace windowLocation.toString().replace(/#.*$/, '') + '#' + frag
		        document.title = title
		
		        updateUri()
		else
		    # We override native implementations to augment them with `document.title`
		    # changing to make use of the title property seemingly ignored in most
		    # browsers implementing push/replaceState natively, as well as 
		    # calling `updateUri` to update all observables of the `location` API.
		    nativeHistory = windowHistory
		    nativePushState = windowHistory.pushState
		    nativeReplaceState = windowHistory.replaceState
		
		    windowHistory.pushState = (state, title, frag) ->
		        nativePushState.call nativeHistory, state, title, frag
		        document.title = title
		
		        updateUri()
		
		    windowHistory.replaceState = (state, title, frag) ->
		        nativeReplaceState.call nativeHistory, state, title, frag
		        document.title = title
		
		        updateUri()
		bo.routing = {}
		
		# Represents a single route within an application, the definition of a URL
		# that may contain a set of parameters that can be used to navigate
		# between screens within the application.
		#
		# A route is defined by its name (which is unique within an application) plus
		# a route definition, which is a static URL which may contain any number
		# of parameters, plus an optional, single 'splat' parameter.
		#
		# Example: /Email/Show/{id}
		#
		# The above URL has a single parameter, 'id', which must be present for
		# this route to match an incoming URL, such as '/Email/Show/1254', where id would be
		# 1254. These parameter types will match until the end of the URL or the next 
		# forward slash. Any characters will be consumed, no checking is done at a route level.
		#
		# A 'splat' parameter allow capturing of any characters from a given point to the end
		# of the URL, consuming any forward slashes, unlike normal parameters:
		#
		# Example: /File/{*filePath}
		#
		# The above URL has a single splat parameter, 'filePath', that will match all characters
		# in a URL after the /File/ prefix, such as '/File/root/pictures/myPicture.png', where
		# filePath would be 'root/pictures/myPicture.png'.
		class Route
		    paramRegex = /{(\*?)(\w+)}/g
		
		    # Constructs a new route, with a name and route url.
		    constructor: (@name, @url, @callback, @options) ->
		        @title = options.title
		
		        @requiredParams = []
		        @paramNames = []
		
		        routeDefinitionAsRegex = @url.replace paramRegex, (_, mode, name) =>
		            @paramNames.push name
		
		            if mode isnt '*'
		                @requiredParams.push name
		
		            if mode is '*' then '(.*)' else '([^/]*)'
		
		        if routeDefinitionAsRegex.length > 1 and routeDefinitionAsRegex.charAt(0) is '/'
		            routeDefinitionAsRegex = routeDefinitionAsRegex.substring 1 
		
		        @incomingMatcher = new RegExp "#{routeDefinitionAsRegex}/?$", "i"
		
		    match: (path) ->
		        matches = path.match @incomingMatcher
		        
		        if matches
		            params = {}
		            
		            for name, index in @paramNames
		                params[name] = matches[index + 1] 
		
		            params
		
		    buildUrl: (parameters = {}) ->
		        if @_allRequiredParametersPresent parameters        
		            @url.replace paramRegex, (_, mode, name) =>
		                ko.utils.unwrapObservable (parameters[name] || '')
		
		    _allRequiredParametersPresent: (parameters) ->
		        _.all(@requiredParams, (p) -> parameters[p]?)
		
		    toString: ->
		        "#{@name}: #{@url}"
		
		# Defines the root of this application, which will typically be the
		# root of the address (e.g. /). This can be set to a subdirectory if
		# required to ensure that when reading and writing to the URL fragment
		# (which in `pushState` enabled browsers is the path of the URL) the
		# root is ignored and maintained.
		
		# TODO: Take this into account, spec it out etc.
		root = '/'
		
		# A route table that manages a number of routes, providing the ability
		# to get a route from a URL or creating a URL from a named route and
		# set of parameters.
		class bo.routing.Router
		
		    constructor: ->
		        @routes = {}
		
		        # Handle messages that are raised by the location component
		        # to indicate the URL has changed, that the user has navigated
		        # to a new page (which is also raised on first load).
		        bo.bus.subscribe 'urlChanged:external', (msg) =>
		            matchedRoute = @getRouteFromUrl msg.url
		
		            if matchedRoute is undefined
		                bo.bus.publish 'routeNotFound', 
		                    url: msg.url
		            else 
		                @_doNavigate msg.path, matchedRoute.route, matchedRoute.parameters
		
		    _doNavigate: (url, route, parameters) ->
		        route.callback? parameters
		
		        bo.bus.publish "routeNavigated:#{route.name}",
		            route: route
		            parameters: parameters
		
		        @currentUrl = url
		
		    # Adds the specified named route to this route table. If a route
		    # of the same name already exists then it will be overriden
		    # with the new definition.
		    #
		    # The URL *must* be a relative definition, the route table will
		    # not take into account absolute URLs in any case.
		    route: (name, url, callback, options = { title: name }) ->
		        @routes[name] = new Route name, url, callback, options
		
		        @
		
		    # Given a *relative* URL will attempt to find the
		    # route that matches that URL, returning an object that represents
		    # the found route with parameters as:
		    #
		    # {
		    #   `route`: The route object that matched the given URL
		    #   `parameters`: The parameters that were matched based on route, or
		    #      an empty object for no parameters.
		    # }
		    #
		    # Routing will ignore preceeding and trailing slashes, treating
		    # them as optional, meaning for the incoming URL and route definitions
		    # the following are considered equal:
		    #
		    #  * /Contact Us
		    #  * /Contact Us/
		    #  * Contact Us/
		    #  * Contact Us
		    getRouteFromUrl: (url) ->
		        path = (new bo.Uri url, { decode: true }).path
		        match = undefined
		
		        for name, r of @routes
		            matchedParams = r.match path
		
		            if matchedParams?
		                match = { route: r, parameters: matchedParams }
		
		        match
		    
		    # Gets the named route, or `undefined` if no such route
		    # exists.
		    getNamedRoute: (name) ->
		        @routes[name]
		
		    navigateTo: (name, parameters = {}) ->
		        url = @buildUrl name, parameters
		
		        if url?
		            route = @getNamedRoute name
		
		            @_doNavigate url, route, parameters
		
		            bo.location.routePath url
		            document.title = route.title
		
		            return true
		
		        false
		
		    # Builds a URL based on a named route and a set of parameters, or
		    # `undefined` if no such route exists or the parameters do not
		    # match.
		    buildUrl: (name, parameters) ->
		        route = @getNamedRoute name
		        url = route?.buildUrl parameters
		
		        if route is undefined
		            bo.log.warn "The route '#{name}' could not be found."
		
		        if url is undefined
		            bo.log.warn "The parameters specified are not valid for the '#{name}' route."
		
		        url
		
		# A binding handler that identifies it should directly apply to any
		# elements with a given name with should have a `tag` property that
		# is either a `string` or an `object`. 
		#
		# A string representation takes the form of
		# `appliesToTagName[->replacedWithTagName]`, for example 'input'
		# or 'tab->div' to indicate a binding handler that applies to
		# an input element but requires no transformation and a binding
		# handler that should replace any `tab` elements with a `div` element.
		#
		# An object can be specified instead of a string which consists of the
		# following properties:
		#
		# * `appliesTo`: The name of the tag (*must be uppercase*) the binding
		# handler applies to and should be data-bound to in all cases.
		#
		# * `replacedWith`: An optional property that identifies the name of the
		# tag that the element should be replaced with. This is needed to support
		# older versions of IE that can not properly support custom, non-standard
		# elements out-of-the-box.
		tagBindingProvider = ->
		    realBindingProvider = new ko.bindingProvider()
		
		    # The definition of what tag to apply a binding handler, and the
		    # optional replacement element name can be defined as a string
		    # which needs to be parsed.
		    processBindingHandlerTagDefinition = (bindingHandler) ->
		        if _.isString bindingHandler.tag
		            split = bindingHandler.tag.split "->"
		
		            if split.length is 1
		                bindingHandler.tag =
		                    appliesTo: split[0].toUpperCase()
		            else
		                bindingHandler.tag =
		                    appliesTo: split[0].toUpperCase()
		                    replacedWith: split[1]
		
		    mergeAllAttributes = (source, destination) ->
		        if document.body.mergeAttributes
		            destination.mergeAttributes source, false
		        else
		            for attr in source.attributes
		                destination.setAttribute attr.name, attr.value
		
		    findTagCompatibleBindingHandlerNames = (node) ->
		        if node.tagHandlers?
		            node.tagHandlers
		        else
		            tagName = node.tagName
		
		            if tagName?
		                _.filter _.keys(koBindingHandlers), (key) ->
		                    bindingHandler = koBindingHandlers[key]
		
		                    processBindingHandlerTagDefinition bindingHandler
		
		                    bindingHandler.tag?.appliesTo is tagName
		            else
		                []
		
		    processOptions = (node, tagBindingHandlerName, bindingContext) ->
		        options = true
		        optionsAttribute = node.getAttribute 'data-option'
		
		        if optionsAttribute
		            # To use the built-in parsing logic we will create a binding
		            # string that would be used if this binding handler was being used
		            # in a normal data-bind context. With the parsed options we can then
		            # extract the value that would be passed for the valueAccessor.
		            optionsAttribute = "#{tagBindingHandlerName}: #{optionsAttribute}"                
		            options = realBindingProvider.parseBindingsString optionsAttribute, bindingContext
		            options = options[tagBindingHandlerName]
		
		        options
		
		    @preprocessNode = (node) ->
		        tagBindingHandlerNames = findTagCompatibleBindingHandlerNames node
		
		        # We assume that if this is for a 'tag binding handler' it refers to an unknown
		        # node so we use the specified replacement node from the binding handler's
		        # tag option.
		        if tagBindingHandlerNames.length > 0
		            node.tagHandlers = tagBindingHandlerNames
		
		            replacementRequiredBindingHandlers = _.filter tagBindingHandlerNames, (key) ->
		                koBindingHandlers[key].tag?.replacedWith?
		            
		            if replacementRequiredBindingHandlers.length > 1
		                throw new Error "More than one binding handler specifies a replacement node for the node with name '#{node.tagName}'."
		
		            if replacementRequiredBindingHandlers.length == 1
		                tagBindingHandler = koBindingHandlers[replacementRequiredBindingHandlers[0]]
		
		                nodeReplacement = document.createElement tagBindingHandler.tag.replacedWith
		                mergeAllAttributes node, nodeReplacement
		
		                ko.utils.replaceDomNodes node, [nodeReplacement]
		
		                nodeReplacement.tagHandlers = tagBindingHandlerNames
		                nodeReplacement.originalTagName = node.tagName
		
		                return nodeReplacement
		
		    @nodeHasBindings = (node, bindingContext) ->
		        tagBindingHandlers = findTagCompatibleBindingHandlerNames node
		        isCompatibleTagHandler = tagBindingHandlers.length > 0
		
		        isCompatibleTagHandler or realBindingProvider.nodeHasBindings(node, bindingContext)
		
		    @getBindings = (node, bindingContext) ->
		        # parse the bindings with the real binding provider
		        existingBindings = (realBindingProvider.getBindings node, bindingContext) || {}
		
		        tagBindingHandlerNames = findTagCompatibleBindingHandlerNames node
		        
		        if tagBindingHandlerNames.length > 0
		            for tagBindingHandlerName in tagBindingHandlerNames 
		                existingBindings[tagBindingHandlerName] = processOptions node, tagBindingHandlerName, bindingContext
		
		        existingBindings
		
		    @
		
		ko.bindingProvider.instance = new tagBindingProvider()

		bo.ViewModel =
		    extend: (definition) ->
		        viewModel = ->
		
		        for own key, value of definition
		            if not _.isFunction value
		                viewModel.prototype[key] = value
		        
		        viewModel
		#
		# ** View Model Lifecycle **
		#
		#         ┌──────────────────────────────┐
		# init →  │ → beforeShow → show → hide ↓ │ → destroy
		#         │ ↑  ←  ←  ←  ←  ←  ←  ←  ←  ← │
		#         └──────────────────────────────┘
		#contactUs = bo.ViewModel.create
		#    template: 'e:Contact Us' 
		
		    # The very first time this view model is accessed. Should
		    # be used to set-up any one-time data.
		#    init: () ->
		
		    # When this view model is shown, executed
		    # every time the view model is to be shown to the
		    # user after having been disposed / deactivated / hidden.
		    #
		    # Any promises returned from this method will have to be
		    # executed before the view this view model represents is
		    # actually shown to the user, to avoid the flash of
		    # content being shown, followed by further loading screens to
		    # load data required by this view model.
		#    beforeShow: (parameters) ->
		
		    # Once this view model has been shown this method is called,
		    # to allow further work to be performed that does not
		    # need to be done before actually showing this view to the user.
		    #
		    # This method will be called once all work of the beforeShow method
		    # has been completed and the view has been bound to the view model.
		#    show: (parameters) ->
		
		    # Called when the view this view model is bound to is being hidden from
		    # the user, used to dispose of resources this view model may be holding
		    # on to which are no longer required.
		    #
		    # Note that a hidden view may be shown once again in the future, starting
		    # the lifecycle from the `beforeShow` method.
		#    hide: ->
		
		    # Called when this view model should be completely destroyed, such
		    # that it will never be shown again to the user (a different view model
		    # instance will need to be recreated to use the view model again).
		#    destroy: ->
		
		#$router
		#    .route('View User', '/Users/{userId}/View', -> $app.show(viewUser))
		#    .route('Edit User', '/Users/{userId}/Edit', -> $app.show(editUser))
		#    .route('Edit User', '/Users/{userId}/Edit', function() {
		#       $regionManager.show(ViewUserViewModel);
		#       // OR: $regionManager.show([{ viewModel: ViewUserViewModel, region: 'main' }, ...], params);
		#     });
		
		# We want to register in to the sitemap. This puts a /Users/View element
		# that will, when clicked, navigate to the 'View User' route. Sitemap
		# would listen for routeNavigated events for determining current
		# route being shown for breadcrumb purposes.
		#
		#$sitemap
		#    .register '/Users/View', 'View User'
		#    .register '/Users/Edit', 'Edit User'

		# # Overview
		#
		# A key component of any `blackout` application, the `part` binding handler
		# is responsible for managing a section of a page, to provide simple
		# lifecycle management for showing `parts`.
		#
		# A part is the lowest level of abstraction for view model and view rendering,
		# providing only a small amount of functionality on the top of the `template`
		# binding handler in `knockout`, as described in details below.
		#
		# A part is defined by a template (either named or anonymous) and a
		# `view model`, a view model being defined as nothing more than a 
		# simple object with optional methods and properties that can affect
		# the rendering and hook in to simple lifecycle management.
		#
		# A part takes a single parameter, which is the `view model` that is to
		# be shown. If this property is an observable that if that observable is
		# updated the binding handler will `hide` the currently bound view model
		# and bind the new one and (optionally) switch out the template.
		#
		# ## Part Manager Integration
		#
		# Typically an app will use a `part manager` to manage the parts within the
		# system, to provide further semantics on top of a `part` binding handler to integrate
		# with the routing system and provide features such as checking for the dirty
		# state of parts and managing multiple parts within an application.
		#
		# ## Lifecycle
		#
		#             ┌──────────────────────────────┐
		# set part →  │ → beforeShow → show → hide → │  → part unset 
		#             └──────────────────────────────┘
		#
		# The lifecycle hooks that the `part` binding handler provides are very
		# simple, providing no automatic management such as garbage collection or
		# unregistering events, it is the responsibility of the `view model`
		# itself to perform these actions, typically aided by using the `bo.ViewModel`
		# class and associated methods to provide more structure for view models.
		#
		# The above diagram demonstrates the lifecycle methods that, if found on the
		# `view model` will be invoked when this binding handler binds to it.
		#
		# Each method will be called in turn, as demonstrated above, with the following
		# behaviours for each:
		#
		# * `beforeShow`: This function will be called before the template is bound / shown
		#    to the user. It is expected this is where most processing will occur, where
		#    data required for the view will be loaded. It is for this reason that this
		#    binding handler will wait until all AJAX requests have completed before
		#    continuining execution. This automatic listening of all AJAX requests relies on the
		#    `bo.ajax.listen` functionality, which means only AJAX requests executed through
		#    the `bo.ajax` methods will be listened to.
		#
		# * `show`: Once the `beforeShow` function has continued execution the template
		#    will be rendered, with the `view model` set as the data context. Once the
		#    template has been rendered by `knockout` the `show` function of the `view model`
		#    will be called.
		koBindingHandlers.part =
		    init: (element, valueAccessor) ->
		        viewModel = ko.utils.unwrapObservable valueAccessor() || {}
		
		        realValueAccessor = ->
		            { data: viewModel, name: viewModel.viewName }
		
		        koBindingHandlers.template.init element, realValueAccessor
		
		    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
		        viewModel = ko.utils.unwrapObservable valueAccessor()
		
		        if not viewModel?
		            return
		
		        realValueAccessor = ->
		            { data: viewModel, name: viewModel.viewName }
		
		        lastViewModel = ko.utils.domData.get element, '__part__lastViewModel'
		
		        if lastViewModel? and lastViewModel.hide?
		            lastViewModel.hide()
		
		        deferred = new $.Deferred()
		
		        if viewModel.beforeShow?
		            deferred = bo.ajax.listen ->
		                viewModel.beforeShow()
		        else
		            # Resolve immediately, nothing to wait for
		            deferred.resolve()
		
		        deferred.done ->
		            koBindingHandlers.template.update element, realValueAccessor, allBindingsAccessor, viewModel, bindingContext
		
		            if viewModel.show?
		                viewModel.show()
		
		            ko.utils.domData.set element, '__part__lastViewModel', viewModel
		regionManagerContextKey = '$regionManager'
		
		class bo.RegionManager
		    constructor: ()->
		        @defaultRegion = undefined
		        @regions = {}
		
		    show: (viewModel) ->
		        # If a single region has been set use whatever name was given.
		        if (_.keys @regions).length is 1
		            @regions[_.keys(@regions)[0]] viewModel
		        else if @defaultRegion?
		            @regions[@defaultRegion] viewModel
		        else
		            throw new Error 'Cannot use show when multiple regions exist'
		    
		    showAll: (viewModels) ->
		        for regionKey, vm of viewModels
		            if @regions[regionKey] is undefined
		                throw new Error "This region manager does not have a '#{regionKey}' region."
		
		            @regions[regionKey] vm
		
		        # Avoid automated return.
		        undefined
		
		    register: (name, isDefault) ->
		        if isDefault
		            @defaultRegion = name
		
		        @regions[name] = ko.observable()
		
		    get: (name) ->
		        @regions[name]()
		
		# A `regionManager` is a binding handler that is typically applied at the root
		# of a document structure to provide the necessary management of `regions` (of which
		# there may only be one in many applications) within a `blackout` application.
		#
		# Once a `regionManager` has been bound there may be any number of `region` elements
		# as children (they do not have to be direct descendants) that are managed by
		# the region manager.
		#
		# These regions define 'holes' in the document structure into which view `parts` will
		# be rendered. A region manager and associated regions are a small management layer 
		# on top of the `part` binding handler to allow the management of complexity when
		# it comes to multiple regions within a single application, to avoid individual modules
		# and parts of the system knowing too much about these regions.
		koBindingHandlers.regionManager =
		    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) -> 
		        regionManager = ko.utils.unwrapObservable valueAccessor()
		
		        regionManagerProperties = {}
		        regionManagerProperties[regionManagerContextKey] = regionManager
		
		        innerBindingContext = bindingContext.extend regionManagerProperties
		
		        ko.applyBindingsToDescendants innerBindingContext, element
		 
		        { controlsDescendantBindings: true }
		
		koBindingHandlers.region =
		    tag: 'region->div'
		
		    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
		        regionManager = bindingContext[regionManagerContextKey]
		
		        if regionManager is undefined
		            throw new Error 'region binding handler / tag must be a child of a regionManager'
		
		        regionId = element.id or 'main'
		        isDefault = (element.getAttribute 'data-default') is 'true'
		
		        regionManager.register regionId, isDefault
		
		        koBindingHandlers.part.init element, (() -> {}), allBindingsAccessor, viewModel, bindingContext
		
		    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
		        regionManager = bindingContext[regionManagerContextKey]
		        regionId = element.id or 'main'
		
		        koBindingHandlers.part.update element, (() -> regionManager.get regionId), allBindingsAccessor, viewModel, bindingContext
	)

)(window, document, window["jQuery"], window["ko"])