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

    match: (incoming) ->
        bo.arg.ensureString incoming, 'incoming'

        matches = incoming.match @incomingMatcher
        
        if matches
            matchedParams = {}
            matchedParams[name] = matches[index + 1] for name, index in @paramNames
            matchedParams

    create: (args = {}) ->
        if @_allParametersPresent args
        
            @definition.replace paramRegex, (_, mode, name) =>
                args[name]

    _allParametersPresent: (args) ->
        _.all(@paramNames, (p) -> args[p]?)

    toString: ->
        "#{@name}: #{@definition}"

# A RouteTable is responsible for managing a set of routes, with only one RouteTable
# instance being available in a single application.
#
# A RouteTable will maintain a list of registered routes in the order in which they
# were registered, meaning when creating or matching against routes it is important
# more general routes appear after specific routes, as is the case in the 
# ASP.NET Routing engine.
class RouteTable
    constructor: ->
        @routes = {}

    # Removes all routes from this routing table.
    clear: ->
        @routes = {}

    # Gets the route with the given name from this table, returning undefined
    # if no such route exists.
    getRoute: (name) ->
        bo.arg.ensureString name, 'name'

        @routes[name]
        
    add: (routeOrName, routeDefinition) ->
        bo.arg.ensureDefined routeOrName, 'routeOrName'

        if routeOrName instanceof Route
            @routes[routeOrName.name] = routeOrName
        else
            @add new Route routeOrName, routeDefinition

    match: (url) ->
        bo.arg.ensureString url, 'url'

        for own name, route of @routes
            matchedParameters = route.match url 
                                   
            if matchedParameters
                return {
                    route: route
                    parameters: matchedParameters
                }
    
    create: (name, parameters) ->
        bo.arg.ensureString name, 'name'
        
        if not @routes[name]
            throw "Cannot find the route '#{name}'."

        @routes[name].create parameters

class HistoryJsRouter
    constructor: (@historyjs, @routeTable) ->
        @persistedQueryParameters = {}
        @transientQueryParameters = {}

        @currentRoute = ko.observable()

        jQuery(window).bind 'statechange', => 
            if not @navigating
                @_handleExternalChange()

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
        @persistedQueryParameters[name] = value if isPersisted
        @transientQueryParameters[name] = value if not isPersisted
        
        @historyjs.pushState null, null, @_generateUrl @_getNormalisedHash()

    # Navigates to a named route with parameters.
    #
    # Navigation to a named route will replace the current URL with the generated
    # route's URL, whilst maintaining the current query string (if one exists).
    navigateTo: (routeName, parameters = {}, checkPreconditions = true) ->
        route = @routeTable.getRoute routeName
        
        if not route
            throw "Cannot find the route '#{routeName}'."

        routeUrl = route.create parameters

        if routeUrl		    
            eventParams = { route: route, parameters: parameters }

            if not checkPreconditions or (@_raiseRouteNavigatingEvent eventParams)
                @navigating = true

                @transientQueryParameters = {}
                
                @historyjs.pushState null, null, @_generateUrl routeUrl
                @_raiseRouteNavigatedEvent eventParams
                
                @navigating = false
            
    # Initialises this router which involves looking at the current URL and
    # determining the currently selected route, raising a RouteNavigatedTo event to indicate
    # a 'change'.
    #
    # This method should be called after all routes have been registered and event handlers
    # subscribed so when it is called those subscribers can react accordingly to the initial route.
    initialise: ->
        @_handleExternalChange()

    _handleExternalChange: ->
        routeNavigatedTo = @routeTable.match @_getNormalisedHash()

        if routeNavigatedTo
            @_raiseRouteNavigatedEvent { route: routeNavigatedTo.route, parameters: routeNavigatedTo.parameters }   
        else
            bo.bus.publish "unknownUrlNavigatedTo", { url: @historyjs.getState().url } 
            
    # Given a 'route URL' will generate the full URL that should be pushed as the new state, including
    # any current query string paramaters.
    _generateUrl: (routeUrl) ->
        queryString = new bo.QueryString()
        queryString.setAll @transientQueryParameters
        queryString.setAll @persistedQueryParameters

        routeUrl + queryString.toString()  
            
    _raiseRouteNavigatedEvent: (routeData) ->    
        @currentRoute routeData.route
        bo.bus.publish "routeNavigatedTo:#{routeData.route.name}", routeData

    _raiseRouteNavigatingEvent: (routeData) ->    
        bo.bus.publish "routeNavigatingTo:#{routeData.route.name}", routeData

    # Gets a normalised hash value, a string that can be used to determine what route is
    # currently being accessed. This will strip any leading periods and remove the query string,
    # leaving a root-level URL that should match a route definition.
    _getNormalisedHash: () ->
        currentHash = @historyjs.getState().hash
        currentHash = currentHash.substring(1) if currentHash.startsWith('.')
        currentHash = currentHash.replace bo.query.current().toString(), ''

routeTableInstance = new RouteTable()
routerInstance = new HistoryJsRouter(window.History, routeTableInstance)

bo.routing =
    Route: Route
    
    routes: routeTableInstance
    router: routerInstance