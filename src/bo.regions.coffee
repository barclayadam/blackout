# The region manager is a key component of any application, being responsible for
# maintaining all 'parts' within the application and to provide the plumbing required
# to support navigation throughout the application by using the routing mechanism
# to load parts of the application.
class bo.RegionManager
    @reactivateEvent: "reactivateParts"

    constructor: () ->
        @isRegionManager = true

        @routeNameToParts = {}

        @currentRoute = null
        @currentParameters = null
        @currentParts = ko.observable {}
        @isLoading = ko.observable false

        bo.bus.subscribe "routeNavigatedTo", (data) => @_handleRouteNavigatedTo data
        bo.bus.subscribe "routeNavigatingTo", (data) => @canDeactivate()
        bo.bus.subscribe "reactivateParts", () => @reactivateParts()

    partsForRoute: (routeName) ->
        @routeNameToParts[routeName]

    register: (routeName, part) ->
        bo.arg.ensureDefined routeName, 'routeName'
        bo.arg.ensureDefined part, 'part'

        throw "Cannot find route with name '#{routeName}'" if (bo.routing.routes.getRoute routeName) is undefined

        @routeNameToParts[routeName] = [] if not @routeNameToParts[routeName]
        @routeNameToParts[routeName].push part

    reactivateParts: () ->
        part.activate @currentParameters for region, part of @currentParts()

    canDeactivate: (options = {}) ->
        hasDirtyPart = _.any(@currentParts(), (part) -> !part.canDeactivate())

        if hasDirtyPart > 0
            if options.showConfirmation is false
                false
            else
                window.confirm "Do you wish to lose your changes?"
        else
            true

    _handleRouteNavigatedTo: (data) ->
        data.parameters ?= {}

        if @_isRouteDifferent data.route
            partsRegisteredForRoute = @partsForRoute data.route.name

            if not partsRegisteredForRoute
                console.log "Could not find any parts registered against the route '#{data.route.name}'"
            else
                @isLoading true
                @_deactivateAll()

                partPromises = []
                currentPartsToSet = {}

                for part in partsRegisteredForRoute
                    partPromises = partPromises.concat part.activate data.parameters
                    currentPartsToSet[part.region] = part

                jQuery.when.apply(@, partPromises).done =>
                    @currentParts currentPartsToSet
                    @currentRoute = data.route.name
                    @currentParameters = data.parameters
                    @isLoading false

    _deactivateAll: ->
        part.deactivate() for region, part of @currentParts()

    _isRouteDifferent: (route) ->
        !@currentRoute or @currentRoute isnt route.name

currentPartsValueAccessor = (regionManager) ->
    -> { 'ifnot': _.isEmpty(regionManager.currentParts()), 'templateEngine': ko.nativeTemplateEngine.instance, 'data': regionManager }

ko.bindingHandlers.regionManager =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        regionManager = ko.utils.unwrapObservable valueAccessor()
        $element = jQuery(element)

        valueAccessor = currentPartsValueAccessor regionManager
        ko.bindingHandlers.template.init element, valueAccessor , allBindingsAccessor, regionManager, bindingContext

        regionManager.isLoading.subscribe (isLoading) ->
            $element.toggleClass 'is-loading', isLoading

    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        regionManager = ko.utils.unwrapObservable valueAccessor()

        valueAccessor = currentPartsValueAccessor regionManager
        ko.bindingHandlers.template.update element, valueAccessor, allBindingsAccessor, regionManager, bindingContext

ko.bindingHandlers.region =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        throw 'A region binding must be enclosed within a regionManager binding.' if not (viewModel instanceof bo.RegionManager)

        { "controlsDescendantBindings": true }

    update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        region = valueAccessor()
        regionManager = viewModel
        part = regionManager.currentParts()[region]

        if part?
            ko.renderTemplate part.templateName, part.viewModel, {}, element, "replaceChildren"
        else
            jQuery(element).remove()