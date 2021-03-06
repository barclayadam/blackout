toOrderDirection = (order) ->
    if order is 'asc' or order is 'ascending'
        'ascending'
    else 
        'descending'

getSortOrder = (a, b) ->
    if a is b
        0
    else if (_.isString a) and (_.isString b)
        if a.toLowerCase() < b.toLowerCase() then -1 else 1
    else
        if a < b then -1 else 1


# A DataSource is a representation of an array of data (of any kind) that
# is represented in a consistent manner, providing functionality such as
# server and client-side paging and sorting over the top of a data provider
# that is the specific implementation of a method of loading said data (e.g.
# directly providing an array, using a `query` to load data or any operation
# that can provide an array of data).
#
# #Paging#
#
# The data source supports client and server side paging, with the ability to
# have both enabled within a single source of data which can be useful to
# provide a small paging size for display purposes yet a larger server-side
# page to allow fewer calls back to the server to be made.
#
# If paging is enabled then the `pageNumber`, `pageSize`, `pages` and `pageItems` 
# observable properties becomes important, as they represent the (client-side)
# page (1-based) currently being represented by the `pageItems` observable, the
# size of the client-side page and an observable array of pages, an object with
# `pageNumber` and `isSelected` properties, in addition to a `select` method to
# select the represented page.
#
# ##Client-Side Paging##
#
# To enable client-side paging the `clientPaging` option must be provided in
# the `options` at construction time, specifying the size of the page. Once this
# option has been enabled `pageItems` will be the items to display for the
# current (see `pageNumber`) page.
#
# ##Server-Side Paging##
#
# To enable server-side paging the `serverPaging` option must be provided in 
# the `options` at construction time, specying the size of the page. In addition
# the `provider` must correctly adhere to the page size and number passed to it as 
# the `pageSize` and `pageNumber` properties of its `loadOptions` parameter.
class bo.DataSource extends bo.Bus
    constructor: (@options) ->
        # An observable property that represents whether or not this data source is
        # currently loading some data (using the specified `provider`).
        @isLoading = ko.observable false

        @_hasLoadedOnce = false
        @_serverPagingEnabled = @options.serverPaging > 0
        @_clientPagingEnabled = @options.clientPaging > 0

        @pagingEnabled = @_serverPagingEnabled or @_clientPagingEnabled

        # Stores the items as loaded (e.g. without sorting / paging applied
        # when in client-side only mode).
        @_loadedItems = ko.observableArray()

        @sortedBy = ko.observable();

        # A textual description of the sorting that is currently in-place
        # on this data source, which will be one of:
        # * `ascending` - The items themselves are ordered in ascending order.
        # * `descending` - The items themselves are ordered in descending order.
        # * `myProperty (ascending|descending)[, anotherProperty]` - The properties and
        # their (optional) direction that are being ordered.
        @sorting = ko.computed =>
            sortedBy = @sortedBy()

            if sortedBy?
                if _.isString sortedBy
                    sortedBy
                else if sortedBy.length > 0
                    _.reduce sortedBy, ((memo, o) -> 
                        prop = "#{o.name} #{o.order}"

                        if memo 
                            "#{memo}, #{prop}" 
                        else 
                            prop
                    ), ''

        @_sortFunction = ko.observable()

        @items = ko.computed =>
            if @_sortFunction()?
                @_loadedItems().sort @_sortFunction()
            else
                @_loadedItems()

        if @options.searchParameters?
            @searchParameters = ko.computed => ko.toJS options.searchParameters

            @searchParameters.subscribe =>
                if @_hasLoadedOnce
                    @load true
        else
            @searchParameters = ko.observable {}

        @_setupPaging()
        @_setupInitialData()

    getPropertySortOrder: (propertyName) ->
        sortedBy = @sortedBy()

        if sortedBy? and sortedBy.length > 0
            ordering = _.find sortedBy, (o) -> o.name is propertyName            
            ordering?.order    

    # Sorts the items in ascending order, assuming that the items theirselves
    # can be ordered using the less than (<) operator. 
    sort: ->
        if not @_serverPagingEnabled
            @_sortFunction (a, b) -> getSortOrder a, b

        @sortedBy 'ascending'

    # Sorts the items in descending order, assuming that the items theirselves
    # can be ordered using the less than (<) operator.
    sortDescending: ->
        if not @_serverPagingEnabled
            @_sortFunction (a, b) -> getSortOrder b, a

        @sortedBy 'descending'

    sortBy: (propertyNames) ->
        properties = _(propertyNames.split(',')).map (p) ->
            p = jQuery.trim p

            indexOfSpace = p.indexOf ' '

            if indexOfSpace > -1
                name: p.substring 0, indexOfSpace
                order: toOrderDirection p.substring indexOfSpace + 1
            else
                name: p
                order: 'ascending'

        if not @_serverPagingEnabled
            @_sortFunction (a, b) -> 
                for p in properties
                    order = getSortOrder a[p.name], b[p.name]

                    if order != 0
                        return if p.order is 'ascending' then order else order * -1

                0

        @sortedBy properties

    # Removes the given item from this data source.
    #
    # TODO: Define this method in such a way that it will handle server paging
    # better (currently leaves a 'gap', will reshow this item if user visits another
    # page then goes back to the page this item is on).
    remove: (item) ->
        @_loadedItems.remove item

        @totalCount Math.max 0, @totalCount() - 1

        # We are on the last page with only one item, need
        # to navigate back a page.
        if @pageNumber() > @pageCount()
            @pageNumber Math.max 1, @pageNumber() - 1

    # Performs a load of this data source, which will set the pageNumber to 1
    # and then, using the `provider` specified on construction, load the
    # items uing the current search parameters (if any), the page size (if `serverPaging`
    # is enabled), the current order, and the page number (i.e. 1).
    load: (forceReload = false) ->
        currentPageNumber = @pageNumber()

        if @_hasLoadedOnce and !forceReload
            return

        @pageNumber 1

        # serverPaging enabled means subscription to
        # pageNumber to perform re-load so only execute
        # immediately if not enabled, or if current page number
        # is 1 as then subscription not called.
        if forceReload or not @_serverPagingEnabled or currentPageNumber is 1
            @_doLoad forceReload
        else
            bo.utils.resolvedPromise()

    # Performs a load of this data source, unless this data source has already been 
    # loaded, at which point it performs a reload of the data, but doesn't change 
    # any of the parameters.
    reload: ->
        if @_hasLoadedOnce 
            @_doLoad true
        else
            @load()

    # Goes to the specified page number.
    goTo: (pageNumber) ->
        @pageNumber pageNumber

    # Goes to the first page, assuming that either client or server-side paging
    # has been enabled.
    goToFirstPage: ->
        @goTo 1

    # Goes to the last page, assuming that either client or server-side paging
    # has been enabled.
    goToLastPage: ->
        @goTo @pageCount()

    # Goes to the next page, assuming that either client or server-side paging
    # has been enabled at the current page is not the last one (in which case
    # no changes will be made).
    goToNextPage: ->
        @goTo @pageNumber() + 1 if not @isLastPage()

    # Goes to the previous page, assuming that either client or server-side paging
    # has been enabled at the current page is not the first one (in which case
    # no changes will be made).
    goToPreviousPage: ->
        @goTo @pageNumber() - 1  if not @isFirstPage()

    _setupInitialData: ->
        if @options.provider? and _.isArray @options.provider
            @_setData @options.provider
            @goTo 1

        if @options.initialSortOrder?
            @sortBy @options.initialSortOrder

        if @options.autoLoad is true
            @load()

    _setupPaging: ->
        @_lastProviderOptions = -1
        @clientPagesPerServerPage = @options.serverPaging / (@options.clientPaging || @options.serverPaging)

        @pageSize = ko.observable()
        @totalCount = ko.observable(0)
        @pageNumber = ko.observable().extend
            publishable: { message: ((p) -> "pageChanged:#{p()}"), bus: @ }

        @pageItems = ko.computed =>
            if @_clientPagingEnabled and @_serverPagingEnabled
                start = ((@pageNumber() - 1) % @clientPagesPerServerPage) * @pageSize()
                end = start + @pageSize()
                @items().slice start, end
            else if @_clientPagingEnabled
                start = (@pageNumber() - 1) * @pageSize()
                end = start + @pageSize()
                @items().slice start, end
            else
                @items()

        # An observable property that indicates the number of pages that
        # exist within this data source.
        @pageCount = ko.computed =>
            if @totalCount()
                Math.ceil @totalCount() / @pageSize()
            else 
                0

        # An observable property that indicates whether the current page 
        # is the first one.
        @isFirstPage = ko.computed =>
            @pageNumber() is 1

        # An observable property that indicates whether the current page 
        # is the last one.
        @isLastPage = ko.computed =>
            @pageNumber() is @pageCount() or @pageCount() is 0
                
        if @options.serverPaging
            @pageNumber.subscribe =>
                @_doLoad()

            @sorting.subscribe =>
                @_doLoad()
    
    _doLoad: (forceReload = false)->
        if @options.provider? and _.isArray @options.provider
            return

        if not @pageNumber()?
            return

        loadOptions = _.extend {}, @searchParameters()

        if @_serverPagingEnabled
            loadOptions.pageSize = @options.serverPaging
            loadOptions.pageNumber = Math.ceil @pageNumber() / @clientPagesPerServerPage
        
        loadOptions.orderBy = @sorting() if @sorting()?

        if not forceReload and _.isEqual loadOptions, @_lastProviderOptions
            return

        @isLoading true

        deferred = jQuery.Deferred()

        @options.provider loadOptions, ((loadedData) =>
            @_setData loadedData
            @_lastProviderOptions = loadOptions

            @isLoading false

            deferred.resolve()
        ), @

        deferred

    _setData: (loadedData) ->   
        items = []

        if @options.serverPaging
            items = loadedData.items

            @pageSize @options.clientPaging || @options.serverPaging
            @totalCount loadedData.totalCount || loadedData.totalItems || 0
        else
            items = loadedData

            @pageSize @options.clientPaging || loadedData.length
            @totalCount loadedData.length

        if @options.map?
            items = _(items).chain().map(@options.map).compact().value()

        @_loadedItems items
        @_hasLoadedOnce = true
    