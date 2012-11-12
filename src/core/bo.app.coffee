class bo.App
    constructor: ->
        @regionManager = new bo.RegionManager()
        @router = new bo.routing.Router()

    start: ->
        bo.log.info "Starting application"

        ko.applyBindings @

        bo.location.initialise()

koBindingHandlers.app =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        koBindingHandlers.regionManager.init element, (-> valueAccessor().regionManager), allBindingsAccessor, viewModel, bindingContext
