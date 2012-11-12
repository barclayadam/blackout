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

# Initialises the location subsystem, to be called when the application is
# ready to begin receiving messages (`urlChanged:external` messages).
location.initialise = ->
    location.initialised = true

    bo.bus.publish 'urlChanged:external', 
        url: _getFragment()
        path: location.routePath()
        variables: location.routeVariables()
        external: true

# Bind to the popstate event, as polyfilled previously, and convert
# it into a message that is published on the bus for others to
# listen to.
ko.utils.registerEventHandler window, 'popstate', ->
    updateUri()

    if location.initialised
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