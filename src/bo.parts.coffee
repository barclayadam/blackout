#reference "../lib/jquery.js"
#reference "../lib/knockout.js"
#reference "bo.coffee"
#reference "bo.routing.coffee"
#reference "bo.bus.coffee"

# Defines a part within the application, containing all the required metadata
# about a part, such as the name of the template to use, in addition to a small
# numbers of methods used to support the activation / deactivation of
# parts.
#
# It is this class that will be subclassed to construct each individual part,
# setting the necessary options in the constructor and overriding any other
# method as necessary to support the required functionality of the 
# part.
class bo.Part
    @region: "main"

    constructor: (@name, options = {}) ->  
        bo.arg.ensureDefined name, 'name'

        @title = options.title || name
        @region = options.region || Part.region
        @templateName = options.templateName || name
        
        if _.isFunction options.viewModel
            @viewModelTemplate = options.viewModel || {}
        else
            @viewModel = options.viewModel || {}

    canDeactivate: ->	    
        if @viewModel && @viewModel.isDirty? then !(ko.utils.unwrapObservable @viewModel.isDirty) else true
                    
    deactivate: ->
        regionNode = document.getElementById @region
        regionNode.innerHTML = '' if regionNode?

    # Activates this part.
    # The default behaviour on activation is to:
    # 1) Load the template (view) of this part (see @templateName) from the server.
    # 2) Calls the @show method to allow the loading of data (e.g. queries to
    #    fill the part with specific view model concerns).
    # 3) On completion of the show function, remove any current DOM elements from
    #    this parts region, add the template HTML as innerHTML.
    # 4) Apply bindings using this (the current Part) to the content area.
    activate: (parameters) ->
        bo.arg.ensureDefined parameters, 'parameters'

        @_initialiseViewModel()
        
        loadPromises = [@_loadTemplate()]
        showPromises = @_show parameters || []
        showPromises = [showPromises] if not _.isArray showPromises

        jQuery.when.apply(@, loadPromises.concat(showPromises)).done =>
            @viewModel.reset() if @viewModel.reset

            contentContainer = document.getElementById @region

            if contentContainer?
                contentContainer.innerHTML = @templateHtml
                ko.applyBindings @viewModel, contentContainer

    # A function that will be executed on activation of this part, used to
    # set-up this part with the specified parameters (as taken from the URL).
    _show: (parameters) ->
        bo.arg.ensureDefined parameters, 'parameters'

        if @viewModel.show
            @viewModel.show parameters

    _initialiseViewModel: ->
        if @viewModelTemplate
            @viewModel = new @viewModelTemplate() || {}
            @viewModel.initialise() if @viewModel.initialise
        else
            @viewModel.initialise() if @viewModel.initialise
            @_initialiseViewModel = ->
            
    _loadTemplate: ->         
        if not @templateHtml
            jQuery.ajax
                url: "/Templates/Get/#{@templateName}"
                dataType: 'html'
                type: 'GET'
                success: (template) =>
                    @templateHtml = template

# The part manager is a key component of any application, being responsible for 
# maintaining all 'parts' within the application and to provide the plumbing required
# to support navigation throughout the application by using the routing mechanism
# to load parts of the application.
class bo.PartManager
    @reactivateEvent: "PartManager.reactivateParts"

    constructor: () ->
        @routeNameToParts = {}

        @currentRoute = null
        @currentParameters = null
        @currentParts = ko.observableArray []
        
        bo.bus.subscribe bo.routing.RouteNavigatedToEvent, (data) => @_handleRouteNavigatedTo data
        bo.bus.subscribe bo.routing.RouteNavigatingToEvent, (data) => @canDeactivate()
        bo.bus.subscribe PartManager.reactivateEvent, () => @reactivateParts()

    partsForRoute: (routeName) ->
        @routeNameToParts[routeName]

    register: (routeName, part) ->
        bo.arg.ensureDefined routeName, 'routeName'
        bo.arg.ensureDefined part, 'part'

        throw "Cannot find route with name '#{routeName}'" if (bo.routing.routes.getRoute routeName) is undefined

        @routeNameToParts[routeName] = [] if not @routeNameToParts[routeName]
        @routeNameToParts[routeName].push part

    reactivateParts: () ->
        part.activate @currentParameters for part in @currentParts()

    canDeactivate: (options = {}) ->
        dirtyCount = (true for part in @currentParts() when !part.canDeactivate()).length

        if dirtyCount > 0 
            if options.showConfirmation is false
                false
            else
                window.confirm "Do you wish to lose your changes?"
        else
            true

    _handleRouteNavigatedTo: (data) ->
        data.parameters ?= {}
        changedParts = true
                        
        if @_isRouteDifferent data.route
            partsRegisteredForRoute = @partsForRoute data.route.name

            if not partsRegisteredForRoute
                console.log "Could not find any parts registered against the route '#{data.route.name}'"
            else
                @_deactivateAll()
                
                @_loadPart part, data.parameters for part in partsRegisteredForRoute

                @currentRoute = data.route.name
                @currentParameters = data.parameters

        changedParts

    _deactivateAll: ->
        part.deactivate() for part in @currentParts()
        @currentParts.removeAll()

    _isRouteDifferent: (route) ->
        !@currentRoute or @currentRoute isnt route.name

    _loadPart: (part, parameters) ->        
        @currentParts.push part
        part.activate parameters