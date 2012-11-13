regionManagerContextKey = '$regionManager'

class bo.RegionManager
    constructor: ()->
        @defaultRegion = undefined
        @regions = {}

    showSingle: (viewModel) ->
        # If a single region has been set use whatever name was given.
        if (_.keys @regions).length is 1
            @regions[_.keys(@regions)[0]] viewModel
        else if @defaultRegion?
            @regions[@defaultRegion] viewModel
        else
            throw new Error 'Cannot use show when multiple regions exist'
    
    show: (viewModels) ->
        for regionKey, vm of viewModels
            if @regions[regionKey] is undefined
                throw new Error "This region manager does not have a '#{regionKey}' region."

            @regions[regionKey] vm

        # Avoid automated return.
        undefined

    register: (name, isDefault) ->
        if isDefault
            @defaultRegion = name

        @regions[name] = ko.observable()

    get: (name) ->
        @regions[name]()

# A `regionManager` is a binding handler that is typically applied at the root
# of a document structure to provide the necessary management of `regions` (of which
# there may only be one in many applications) within a `blackout` application.
#
# Once a `regionManager` has been bound there may be any number of `region` elements
# as children (they do not have to be direct descendants) that are managed by
# the region manager.
#
# These regions define 'holes' in the document structure into which view `parts` will
# be rendered. A region manager and associated regions are a small management layer 
# on top of the `part` binding handler to allow the management of complexity when
# it comes to multiple regions within a single application, to avoid individual modules
# and parts of the system knowing too much about these regions.
koBindingHandlers.regionManager =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) -> 
        regionManager = ko.utils.unwrapObservable valueAccessor()

        regionManagerProperties = {}
        regionManagerProperties[regionManagerContextKey] = regionManager

        innerBindingContext = bindingContext.extend regionManagerProperties

        ko.applyBindingsToDescendants innerBindingContext, element
 
        { controlsDescendantBindings: true }

koBindingHandlers.region =
    tag: 'region->div'

    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        regionManager = bindingContext[regionManagerContextKey]

        if regionManager is undefined
            throw new Error 'region binding handler / tag must be a child of a regionManager'

        regionId = element.id or 'main'
        isDefault = (element.getAttribute 'data-default') is 'true'

        regionManager.register regionId, isDefault

        koBindingHandlers.part.init element, (() -> {}), allBindingsAccessor, viewModel, bindingContext

    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        regionManager = bindingContext[regionManagerContextKey]
        regionId = element.id or 'main'

        koBindingHandlers.part.update element, (() -> regionManager.get regionId), allBindingsAccessor, viewModel, bindingContext