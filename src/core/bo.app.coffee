class bo.App
    constructor: ->
        @regionManager = new bo.RegionManager()
        @router = new bo.routing.Router()

    start: ->
        bo.log.info "Starting application"

        # HACK: Figure out better way of starting aqpp after load.
        jQuery =>
            ko.applyBindings @

            bo.location.initialise()

koBindingHandlers.app =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        koBindingHandlers.regionManager.init element, (-> valueAccessor().regionManager), allBindingsAccessor, viewModel, bindingContext
