#reference "bo.coffee"
#reference "bo.bus.coffee"

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

        routeDefinitionAsRegex = routeDefinitionAsRegex.substring 1 if routeDefinitionAsRegex[0] is '/'

        @incomingMatcher = new RegExp "^/?#{routeDefinitionAsRegex}/?$"

        bo.bus.subscribe "navigateToRoute:#{@name}", (options = {}) =>
            @navigateTo options.parameters || {}, options.canVeto

        bo.bus.subscribe 'urlChanged', (data) =>
            if Route.current isnt @
                if (args = @_match data.url) isnt undefined
                    @navigateTo args
        
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
    navigateTo: (args = {}, canVeto = true) ->
        url = @_create args

        if Route.current isnt @
            if (bo.bus.publish "routeNavigating:#{@name}", { url: url, route: @, canVeto: canVeto }) or !canVeto
                Route.current = @
                bo.bus.publish "routeNavigated:#{@name}", { url: url, route: @, parameters: args }        

    _match: (incoming) ->
        bo.arg.ensureString incoming, 'incoming'

        matches = incoming.match @incomingMatcher
        
        if matches
            matchedParams = {}
            matchedParams[name] = matches[index + 1] for name, index in @paramNames
            matchedParams

    _create: (args = {}) ->
        if @_allParametersPresent args        
            @definition.replace paramRegex, (_, mode, name) =>
                args[name]

    _allParametersPresent: (args) ->
        _.all(@paramNames, (p) -> args[p]?)

    toString: ->
        "#{@name}: #{@definition}"

# Cached regex for cleaning leading hashes and slashes .
routeStripper = /^[#\/]/

# Cached regex for detecting MSIE.
isExplorer = /msie [\w.]+/

# The default interval to poll for hash changes, if necessary, is
# twenty times a second.
interval = 50

# Gets the true hash value. Cannot use location.hash directly due to bug
# in Firefox where location.hash will always be decoded.
getHash = (windowOverride) ->
    loc = (if windowOverride then windowOverride.location else window.location)
    match = loc.href.match(/#(.*)$/)
    (if match then match[1] else "")

# History manager shamelessly borrowed (and reworked) from backbone.js (https://github.com/documentcloud/backbone/blob/master/backbone.js)
class HistoryManager
    constructor: (options) ->
        @options          = _.extend {}, { root: '/' }, options
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
    setQueryParameter: (name, value, isPersisted = false) ->
        @navigating = true

        @persistedQueryParameters[name] = value if isPersisted
        @transientQueryParameters[name] = value if not isPersisted
        
        #@historyjs.pushState null, document.title, @_generateUrl()

        @navigating = false

    # Get the cross-browser normalized URL fragment, either from the URL,
    # the hash, or the override.
    getFragment: (fragment, forcePushState) ->
        unless fragment?
            if @_hasPushState or forcePushState
                fragment = window.location.pathname
                fragment += window.location.search || ''
            else
                fragment = getHash()

        fragment = fragment.substr(@options.root.length) unless fragment.indexOf @options.root
        fragment.replace routeStripper, ""

    initialise: ->
        fragment = @getFragment()
        docMode  = document.documentMode
        oldIE    = isExplorer.exec(navigator.userAgent.toLowerCase()) && (!docMode || docMode <= 7)
  
        if oldIE
            @iframe = jQuery('<iframe src="javascript:0" tabindex="-1" />').hide().appendTo('body')[0].contentWindow;
            @navigate(fragment);
      
        # Depending on whether we're using pushState or hashes, and whether
        # 'onhashchange' is supported, determine how we check the URL state.
        if this._hasPushState
            jQuery(window).bind 'popstate', => @_checkUrl()
        else if ('onhashchange' in window) && !oldIE
            jQuery(window).bind 'hashchange', => @_checkUrl()
        else 
            setInterval (=> @_checkUrl()), interval
      
        # Determine if we need to change the base url, for a pushState link
        # opened by a non-pushState browser.
        @fragment = fragment;
      
        loc = window.location;
        atRoot  = loc.pathname == @options.root;
  
        if !this._hasPushState && !atRoot
            # If we've started off with a route from a `pushState`-enabled browser,
            # but we're currently in a browser that doesn't support it...
            @fragment = @getFragment(null, true);
            window.location.replace @options.root + '#' + @fragment;
  
            # Return immediately as browser will do redirect to new url
            return true;
        else if this._hasPushState && atRoot && loc.hash
            # Or if we've started out with a hash-based route, but we're currently
            # in a browser where it could be `pushState`-based instead...
            @fragment = getHash().replace routeStripper, ''
            window.history.replaceState {}, document.title, loc.protocol + '//' + loc.host + @options.root + @fragment
        
        bo.bus.subscribe 'routeNavigated', (d) =>
            @_updateFromRoute d.url, d.route.title

        @_publishCurrent()
  
    # Checks the current URL to see if it has changed, and if it has,
    # calls `_publishCurrent`, normalizing across the hidden iframe.
    _checkUrl: (e) ->
        current = @getFragment()
        current = @getFragment(getHash(@iframe)) if current is @fragment and @iframe
  
        return false if current is @fragment
  
        @_updateFromRoute current if @iframe
        @_publishCurrent()
  
    # Attempt to load the current URL fragment. If a route succeeds with a
    # match, returns `true`. If no defined routes matches the fragment,
    # returns `false`.
    _publishCurrent: (fragmentOverride) ->
        fragment = @fragment = @getFragment fragmentOverride
  
        # Publish message?        
        bo.bus.publish 'urlChanged', 
            url: fragment, 
            fullUrl: fragment
  
    # Save a fragment into the hash history, or replace the URL state if the
    # 'replace' option is passed. You are responsible for properly URL-encoding
    # the fragment in advance.
    _updateFromRoute: (fragment, title) ->  
        document.title = title

        frag = (fragment or "").replace(routeStripper, "")
  
        return  if @fragment is frag
  
        if @_hasPushState
            frag = @options.root + frag  unless frag.indexOf(@options.root) is 0
            @fragment = frag
            window.history.pushState {}, title, frag
        else
            @fragment = frag
            @_updateHash window.location, frag

            if @iframe and (frag isnt @getFragment(@getHash(@iframe)))
                @iframe.document.open().close()
                @_updateHash @iframe.location, frag
  
    # Update the hash location, either replacing the current entry, or adding
    # a new one to the browser history.
    _updateHash: (location, fragment, replace) ->
        location.hash = fragment

bo.routing =
    Route: Route    
    manager: new HistoryManager()

    navigateTo: (routeName, parameters, canVeto = true) ->
        bo.bus.publish "navigateToRoute:#{routeName}", 
            parameters: parameters
            canVeto: canVeto

ko.bindingHandlers.navigateTo =
    init: (element, valueAccessor, allBindingsAccessor) ->
        routeName = valueAccessor()
        parameters = allBindingsAccessor().parameters || {}

        jQuery(element).click (event) ->
            if bo.utils.isElementEnabled allBindingsAccessor
                bo.routing.navigateTo routeName, parameters, allBindingsAccessor().canVeto ? true

                event.preventDefault()
                false