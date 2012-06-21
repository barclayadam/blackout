#reference "bo.coffee"
#reference "bo.bus.coffee"

class RouteTable
    constructor: ->
        @currentUrl = undefined
        @routes = []

        bo.bus.subscribe 'routeCreated', (route) =>
            @_add route

        bo.bus.subscribe 'urlChanged', (msg) =>
            foundRoute = @_find msg.url

            if foundRoute is undefined
                bo.bus.publish 'routeNotFound', { url: msg.url }
            else if @current isnt foundRoute
                foundRoute.route.navigateTo foundRoute.params

    _add: (route) ->
        @routes.push route

        bo.bus.subscribe "navigateToRoute:#{route.title}", (options = {}) =>
            route.navigateTo options.parameters || {}, options.canVeto, options.forceNavigate

        bo.bus.subscribe "routeNavigated:#{route.title}", (msg) =>
            @currentUrl = msg.url

    _find: (url) ->
        for r in @routes
            matchedParams = r.match url

            if matchedParams?
                return { route: r, params: matchedParams }

routeTable = new RouteTable()

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
    @current = undefined
    paramRegex = /{(\*?)(\w+)}/g

    # Constructs a new route, with a name and route definition.
    constructor: (@name, @definition, @options = {}) ->
        bo.arg.ensureString name, 'name'
        bo.arg.ensureString definition, 'definition'

        @title = @options.title || @name
        @metadata = @options.metadata || {}

        @paramNames = []

        routeDefinitionAsRegex = @definition.replace paramRegex, (_, mode, name) =>
            @paramNames.push name
            if mode is '*' then '(.*)' else '([^/]*)'

        if routeDefinitionAsRegex.length > 1 and routeDefinitionAsRegex.charAt(0) is '/'
            routeDefinitionAsRegex = routeDefinitionAsRegex.substring 1 

        @incomingMatcher = new RegExp "^/?#{routeDefinitionAsRegex}/?$"
        
        bo.bus.publish "routeCreated:#{@name}", @

    # Navigates to this route, creating the full URL that this route and the passed parameters
    # represent and raising messages that other parts of the application can respond to, such
    # as the history manager (browser's history) or the `sitemap`.
    #
    # When first called a 'routeNavigating' message will be published, allowing subscribers
    # a chance to veto the navigation by returning `false`. This veto behaviour can be overriden
    # by passing `false` as the second parameter, `canVeto`. When `canVeto` is `false` the event
    # will still be raised, but will not stop the second message, `routeNavigated` from being
    # published.
    navigateTo: (args = {}, canVeto = true, forceNavigate = false) ->
        url = @_create args

        if forceNavigate or routeTable.currentUrl isnt url
            if (bo.bus.publish "routeNavigating:#{@name}", { url: url, route: @, canVeto: canVeto }) or !canVeto
                bo.bus.publish "routeNavigated:#{@name}", { url: url, route: @, parameters: args }        

    match: (incoming) ->
        bo.arg.ensureString incoming, 'incoming'

        matches = incoming.match @incomingMatcher
        
        if matches
            matchedParams = {}
            matchedParams[name] = matches[index + 1] for name, index in @paramNames
            matchedParams

    _create: (args = {}) ->
        if @_allParametersPresent args        
            @definition.replace paramRegex, (_, mode, name) =>
                ko.utils.unwrapObservable args[name]

    _allParametersPresent: (args) ->
        _.all(@paramNames, (p) -> args[p]?)

    toString: ->
        "#{@name}: #{@definition}"


# Core of history management shamelessly borrowed (and reworked) from backbone.js (https://github.com/documentcloud/backbone/blob/master/backbone.js)

# Cached regex for cleaning leading hashes and slashes .
routeStripper = /^[#\/]/

# Cached regex for detecting MSIE.
isExplorer = /msie [\w.]+/

# The default interval to poll for hash changes, if necessary.
interval = 150

# Gets the true hash value. Cannot use location.hash directly due to bug
# in Firefox where location.hash will always be decoded.
getHash = (windowOverride) ->
    loc = (if windowOverride then windowOverride.location else window.location)
    match = loc.href.match(/#(.*)$/)
    (if match then match[1] else "")

class HistoryManager
    constructor: () ->
        @fragment = undefined

        @_hasPushState    = !!(window.history && window.history.pushState)

        @persistedQueryParameters = {}
        @transientQueryParameters = {}

    # Sets a query string paramater, making it a navigatable feature such that
    # the back button will load the URL before this query string parameter
    # was set.
    #
    # Query parameters can be specified to be persisted or not, defaulting to
    # not. A persisted query string parameter will, once set, not be
    # replaced on navigation. Non persistent values on the other hand will
    # be removed when navigating away from the page on which the paramater
    # was set.
    setQueryParameter: (name, value, options = { persistent: false, createHistory: true }) ->
        if options.persistent
            bucket = @persistedQueryParameters
        else
            bucket = @transientQueryParameters

        if value?
            bucket[name] = value
        else
            delete bucket[name]

        if @initialised is true        
            withoutQuery = @fragment.replace bo.QueryString.from(@fragment).toString(), ''
            
            queryString = new bo.QueryString()
            queryString.setAll @transientQueryParameters
            queryString.setAll @persistedQueryParameters
           
            @_updateUrlFromFragment withoutQuery + queryString.toString(), 
                title: document.title
                replace: options.createHistory is false

    getCrossBrowserFragment: ->      
        loc = window.location;
        atRoot  = loc.pathname == bo.config.appRoot;
  
        if !@_hasPushState && !atRoot
            # If we've started off with a route from a `pushState`-enabled browser,
            # but we're currently in a browser that doesn't support it...
            @getFragment null, true
        else if @_hasPushState && atRoot && loc.hash
            # Or if we've started out with a hash-based route, but we're currently
            # in a browser where it could be `pushState`-based instead...
            getHash().replace routeStripper, ''
        else
            @getFragment()

    # Get the cross-browser normalized URL fragment, either from the URL,
    # the hash, or the override.
    getFragment: (fragment, forcePushState) ->
        unless fragment?
            if @_hasPushState or forcePushState
                fragment = window.location.pathname
                fragment += window.location.search || ''
            else
                fragment = getHash()

        fragment = fragment.substr(bo.config.appRoot.length) if fragment.indexOf(bo.config.appRoot) is 0
        fragment.replace routeStripper, ""

        decodeURI fragment 

    initialise: () ->
        fragment = @getFragment()
        docMode  = document.documentMode
        oldIE    = isExplorer.exec(navigator.userAgent.toLowerCase()) && (!docMode || docMode <= 7)
  
        if oldIE
            @iframe = jQuery('<iframe src="javascript:0" tabindex="-1" />').hide().appendTo('body')[0].contentWindow;
            @_updateUrlFromFragment fragment, 
                title: document.title
                replace: true
      
        # Determine if we need to change the base url, for a pushState link
        # opened by a non-pushState browser.
        @fragment = fragment;
      
        loc = window.location;
        atRoot  = loc.pathname == bo.config.appRoot;
  
        if !this._hasPushState && !atRoot
            # If we've started off with a route from a `pushState`-enabled browser,
            # but we're currently in a browser that doesn't support it...
            @fragment = @getFragment null, true
            window.location.replace bo.config.appRoot + '#' + @fragment
  
            # Return immediately as browser will do redirect to new url
            return true;
        else if this._hasPushState && atRoot && loc.hash
            # Or if we've started out with a hash-based route, but we're currently
            # in a browser where it could be `pushState`-based instead...
            @fragment = getHash().replace routeStripper, ''
            window.history.replaceState {}, document.title, loc.protocol + '//' + loc.host + bo.config.appRoot + @fragment
              
        # Depending on whether we're using pushState or hashes, and whether
        # 'onhashchange' is supported, determine how we check the URL state.
        if this._hasPushState
            jQuery(window).bind 'popstate', => @_updateFromCurrentUrl()
        else if (window.onhashchange isnt undefined) && !oldIE
            jQuery(window).bind 'hashchange', => @_updateFromCurrentUrl()
        else 
            setInterval (=> @_updateFromCurrentUrl()), interval

        bo.bus.subscribe 'routeNavigating', (msg) =>
            @transientQueryParameters = {}

        bo.bus.subscribe 'routeNavigated', (msg) =>
            if @initialised
                @_updateFromRouteUrl msg

        @_publishCurrent()
        @initialised = true
  
    # Checks the current URL to see if it has changed, and if it has,
    # calls `_publishCurrent`, normalizing across the hidden iframe.
    _updateFromCurrentUrl: () ->
        current = @getFragment()
        current = @getFragment(getHash(@iframe)) if current is @fragment and @iframe
  
        return false if current is @fragment
  
        @transientQueryParameters = bo.query.current().getAll()

        if @iframe
            @_updateUrlFromFragment current,
                title: document.title
                replace: false

        @_publishCurrent()
  
    _publishCurrent: () ->
        fragment = @fragment = @getFragment()

        queryString = bo.QueryString.from fragment
        queryStringDelimiterIndex = fragment.indexOf '?'

        url = if queryStringDelimiterIndex is -1 then fragment else fragment.substring(0, queryStringDelimiterIndex)
        url = '/' if url is ''

        bo.bus.publish 'urlChanged', 
            url: url
            fullUrl: fragment 
            queryString: queryString
  
    _updateFromRouteUrl: (msg) ->    
        queryString = new bo.QueryString()
        queryString.setAll @transientQueryParameters
        queryString.setAll @persistedQueryParameters
       
        if msg.url.charAt(0) == '/'
            baseUrl = msg.url.substring(1)
        else 
            baseUrl = msg.url
            
        @_updateUrlFromFragment baseUrl + queryString.toString(), 
            title: msg.route.title 
            replace: false

    # Save a fragment into the hash history, or replace the URL state if the
    # 'replace' option is passed. You are responsible for properly URL-encoding
    # the fragment in advance.    
    _updateUrlFromFragment: (fragment, options) ->
        document.title = options.title

        frag = encodeURI (fragment or "").replace(routeStripper, "")
  
        return if @fragment is frag
  
        @fragment = frag

        if @_hasPushState
            frag = bo.config.appRoot + frag unless frag.indexOf(bo.config.appRoot) is 0
            window.history[if options.replace then 'replaceState' else 'pushState'] {}, document.title, frag
        else
            @_updateHash window.location, frag, options.replace

            if @iframe and (frag isnt @getFragment getHash @iframe)
                @iframe.document.open().close()
                @_updateHash @iframe.location, frag
  
    # Update the hash location, either replacing the current entry, or adding
    # a new one to the browser history.
    _updateHash: (location, fragment, replace) ->
        if replace
            location.replace location.toString().replace(/(javascript:|#).*$/, '') + '#' + fragment
        else
            location.hash = fragment

bo.routing =
    # Resets the routing infrastructure, required for testing purposes.
    reset: ->
        routeTable = new RouteTable()

    Route: Route    
    manager: new HistoryManager()

    navigateTo: (routeName, parameters, canVeto = true, forceNavigate = false) ->
        bo.bus.publish "navigateToRoute:#{routeName}", 
            name: routeName
            parameters: parameters
            canVeto: canVeto
            forceNavigate: forceNavigate

# Extends an observable to be linked to a query string parameter of a URL, allowing
# deep links and back button support to interact with values of an observable.
ko.extenders.addressable = (target, paramNameOrOptions) ->
    if typeof paramNameOrOptions is "string"
        paramName = paramNameOrOptions
        persistent = false
        createHistory = true
    else
        paramName = paramNameOrOptions.name ? paramNameOrOptions.key
        persistent = paramNameOrOptions.persistent ? false
        createHistory = paramNameOrOptions.createHistory ? true

    setQueryParameter = (value) ->
        bo.routing.manager.setQueryParameter paramName, value,
            persistent: persistent
            createHistory: createHistory

    set = (newValue) ->
        if newValue? and target() != newValue
            target newValue

    target.subscribe (newValue) ->
        setQueryParameter newValue

    bo.bus.subscribe 'urlChanged', (msg) ->
        set msg.queryString.get paramName

    currentVal = target()
    setQueryParameter currentVal if currentVal?

    # Set value to value of query string immediately
    set bo.query.get paramName

    target

ko.bindingHandlers.navigateTo =
    init: (element, valueAccessor, allBindingsAccessor) ->
        routeName = valueAccessor()
        parameters = allBindingsAccessor().parameters || {}

        jQuery(element).click (event) ->
            if bo.utils.isElementEnabled allBindingsAccessor
                bo.routing.navigateTo routeName, parameters, allBindingsAccessor().canVeto ? true

                event.preventDefault()