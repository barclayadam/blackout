# The region manager is a key component of any application, being responsible for
# maintaining all 'parts' within the application and to provide the plumbing required
# to support navigation throughout the application by using the routing mechanism
# to load parts of the application.
class bo.RegionManager
    @reactivateEvent: "reactivateParts"

    constructor: () ->
        @_activatingParts = undefined

        @currentParts = ko.observable {}
        @isLoading = ko.observable false

        bo.bus.subscribe "reactivateParts", () => @reactivate()

    reactivate: () ->
        @activate _.values @currentParts(), @currentParameters

    canDeactivate: (options = {}) ->
        hasDirtyPart = _.any(@currentParts(), (part) -> !part.canDeactivate())

        if hasDirtyPart > 0
            if options.showConfirmation is false
                false
            else
                window.confirm "Do you wish to lose your changes?"
        else
            true

    activate: (parts, parameters = {}) ->
        if @canDeactivate()
            @_activatingParts = parts

            bo.bus.publish "partsActivating", { parts: parts }
            
            @isLoading true
            @_deactivateAll()

            partPromises = []
            currentPartsToSet = {}

            for part in parts
                partPromises = partPromises.concat part.activate parameters
                currentPartsToSet[part.region] = part

            jQuery.when.apply(@, partPromises).done =>
                if @_activatingParts is parts
                    @currentParts currentPartsToSet
                    @currentParameters = parameters
                    @isLoading false

                    bo.bus.publish "partsActivated", { parts: parts }

    _deactivateAll: ->
        part.deactivate() for region, part of @currentParts()

currentPartsValueAccessor = (regionManager) ->
    -> { 'ifnot': _.isEmpty(regionManager.currentParts()), 'templateEngine': ko.nativeTemplateEngine.instance, 'data': regionManager }

ko.bindingHandlers.regionManager =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        regionManager = ko.utils.unwrapObservable valueAccessor()

        valueAccessor = currentPartsValueAccessor regionManager
        ko.bindingHandlers.template.init element, valueAccessor , allBindingsAccessor, regionManager, bindingContext

        regionManager.isLoading.subscribe (isLoading) ->
            ko.utils.toggleDomNodeCssClass element, 'is-loading', isLoading

    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        regionManager = ko.utils.unwrapObservable valueAccessor()

        valueAccessor = currentPartsValueAccessor regionManager
        ko.bindingHandlers.template.update element, valueAccessor, allBindingsAccessor, regionManager, bindingContext

ko.bindingHandlers.region =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        throw new Error 'A region binding must be enclosed within a regionManager binding.' if not (viewModel instanceof bo.RegionManager)

        { "controlsDescendantBindings": true }

    update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        region = valueAccessor()
        regionManager = viewModel
        part = regionManager.currentParts()[region]

        if part?
            ko.renderTemplate part.templateName, part.viewModel, {}, element, "replaceChildren"
        else
            ko.removeNode element