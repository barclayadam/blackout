class bo.App
    constructor: ->
        @regionManager = new bo.RegionManager()
        @router = new bo.routing.Router()

    start: ->
        bo.log.info "Starting application"

        bo.location.initialise()

        bo.bus.subscribe 'routeNavigated', (msg) =>
            if msg.options?
                @regionManager.show msg.options

koBindingHandlers.app =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        app = valueAccessor()

        koBindingHandlers.regionManager.init element, (-> app.regionManager), allBindingsAccessor, viewModel, bindingContext

        app.start()
 
        { controlsDescendantBindings: true }