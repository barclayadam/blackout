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
    constructor: (@name, @url, @callbackOrOptions, @options) ->
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
        @_routes = {}

        # Handle messages that are raised by the location component
        # to indicate the URL has changed, that the user has navigated
        # to a new page (which is also raised on first load).
        bo.bus.subscribe 'urlChanged:external', (msg) =>
            matchedRoute = @getRouteFromUrl msg.url

            if matchedRoute is undefined
                bo.bus.publish 'routeNotFound', 
                    url: msg.url
            else 
                @_doNavigate msg.url, matchedRoute.route, matchedRoute.parameters

    _doNavigate: (url, route, parameters) ->
        @currentUrl = url
        @currentRoute = route
        @currentParameters = _.extend parameters, new bo.Uri(url).variables

        msg =
            route: route
            parameters: parameters

        if _.isFunction route.callbackOrOptions 
            route.callbackOrOptions parameters
        else if route.callbackOrOptions?
            msg.options = route.callbackOrOptions

        bo.bus.publish "routeNavigated:#{route.name}", msg

    # Adds the specified named route to this route table. If a route
    # of the same name already exists then it will be overriden
    # with the new definition.
    #
    # The URL *must* be a relative definition, the route table will
    # not take into account absolute URLs in any case.
    route: (name, url, callbackOrOptions, options = { title: name }) ->
        @_routes[name] = new Route name, url, callbackOrOptions, options

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

        for name, r of @_routes
            matchedParams = r.match path

            if matchedParams?
                match = { route: r, parameters: matchedParams }

        match
    
    # Gets the named route, or `undefined` if no such route
    # exists.
    getNamedRoute: (name) ->
        @_routes[name]

    navigateTo: (name, parameters = {}) ->
        url = @buildUrl name, parameters

        if url?
            route = @getNamedRoute name

            @_doNavigate url, route, parameters

            bo.location.routePath url

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
        