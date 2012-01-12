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
    constructor: (@name, @definition) ->
        bo.arg.ensureString name, 'name'
        bo.arg.ensureString definition, 'definition'

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
                    bo.bus.publish "routeNavigated:#{@name}", { url: (@_create args), route: @, parameters: args } 
        
        bo.bus.publish "routeCreated:#{@name}", @

    # Navigates to this route, creating the full URL that this route and the passed parameters
    # represent and raising messages that other parts of the application can respond to, such
    # as the history manager (browser's history) or a `region manager`.
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

class HistoryManager
    constructor: () ->
        @historyjs = window.History
        @persistedQueryParameters = {}
        @transientQueryParameters = {}

        @currentRouteUrl = ''

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
        
        @historyjs.pushState null, null, @_generateUrl()

        @navigating = false
            
    # Initialises this router, registering the necessary events to provide URL updating based
    # on the current route (see `routeNavigated` message), in addition to publishing the initial
    # `urlChanged` message to start an application based on the current URL.
    #
    # This method should be called after all routes have been registered and event handlers
    # subscribed so when it is called those subscribers can react accordingly to the initial route.
    initialise: ->
        bo.bus.subscribe 'routeNavigated', (d) =>
            @_updateFromRouteUrl d.url

        jQuery(window).bind 'statechange', => 
            @_handleExternalChange()

        @_handleExternalChange()
          
    _updateFromRouteUrl: (routeUrl) ->
        @navigating = true

        @currentRouteUrl = routeUrl
        @transientQueryParameters = {}
        
        @historyjs.pushState null, null, @_generateUrl()

        @navigating = false

    # Given a 'route URL' will generate the full URL that should be pushed as the new state, including
    # any current query string paramaters.
    _generateUrl: () ->
        queryString = new bo.QueryString()
        queryString.setAll @transientQueryParameters
        queryString.setAll @persistedQueryParameters

        @currentRouteUrl + queryString.toString() 

    _handleExternalChange: ->
        if not @navigating
            bo.bus.publish 'urlChanged', { url: @_getNormalisedHash() }

    # Gets a normalised hash value, a string that can be used to determine what route is
    # currently being accessed. This will strip any leading periods and remove the query string,
    # leaving a root-level URL that should match a route definition.
    _getNormalisedHash: () ->
        currentHash = @historyjs.getState().hash
        currentHash = currentHash.substring(1) if currentHash.startsWith('.')
        currentHash = currentHash.replace bo.query.current().toString(), ''

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