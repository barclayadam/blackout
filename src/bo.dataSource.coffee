toOrderDirection = (order) ->
    if order is undefined or order is 'asc' or order is 'ascending'
        'ascending'
    else 
        'descending'

# A DataSource is a representation of an array of data (of any kind) that
# is represented in a consistent manner, providing functionality such as
# server and client-side paging and sorting over the top of a `data provider`,
# a method of loading said data (e.g. directly providing an array, using a
# `query` to load data or any operation that can provide an array of data).
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
# the `options` at construction time, specifying the size of the page. In addition
# the `provider` must correctly adhere to the page size and number passed to it as 
# the `pageSize` and `pageNumber` properties of its `loadOptions` parameter.
#
# When server-side paging is enabled the server must handle, if specified by the
# options of the `DataSource`:
#
# * Paging
# * Sorting
# * Filtering
# * Grouping
class bo.DataSource
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

        @_sortByAsString = ko.observable()
        @_sortByDetails = ko.observable()

        # When new sorting order given will create the string representation
        # of that sorting order in a normalised fashion (e.g. always use
        # `ascending` or `descending` instead of `asc` or `desc`).
        @_sortByDetails.subscribe (newValue) =>
            normalised = _.reduce newValue, ((memo, o) -> 
                    prop = "#{o.name} #{toOrderDirection(o.order)}"

                    if memo 
                        "#{memo}, #{prop}" 
                    else 
                        prop
                ), ''

            @_sortByAsString normalised

        # The sorting order of this `DataSource`, a textual
        # description of the properties by which the data is sorted.
        #
        # This value, when populated, will be a comma-delimited string
        # with each value being the name of the property being sorted
        # followed by the order (`ascending` or `descending`):
        #
        # `property1 ascending[, property2 descending]` 
        @sortBy = ko.computed
            read: @_sortByAsString

            write: (value) =>
                # TODO: Allow setting an object
                properties = _(value.split(',')).map (p) ->
                    p = ko.utils.stringTrim p

                    indexOfSpace = p.indexOf ' '

                    if indexOfSpace > -1
                        name: p.substring 0, indexOfSpace
                        order: toOrderDirection p.substring indexOfSpace + 1
                    else
                        name: p
                        order: 'ascending'

                @_sortByDetails properties

        # The items that have been loaded, presented sorted, filtered and
        # grouped as determined by the options passed to this `DataSource`.
        @items = ko.computed =>
            if @_sortByDetails()? and not @_serverPagingEnabled
                @_loadedItems().sort (a, b) => 
                    for p in @_sortByDetails()
                        if a[p.name] > b[p.name]
                            return if p.order is 'ascending' then 1 else -1
                        
                        if a[p.name] < b[p.name]
                            return if p.order is 'ascending' then -1 else 1

                    0
            else
                @_loadedItems()

        if @options.searchParameters?
            @searchParameters = ko.computed -> 
                ko.toJS options.searchParameters

            @searchParameters.subscribe =>
                if @_hasLoadedOnce
                    @load()
        else
            @searchParameters = ko.observable {}

        @_setupPaging()
        @_setupInitialData()

    getPropertySortOrder: (propertyName) ->
        sortedBy = @_sortByDetails()

        if sortedBy? and sortedBy.length > 0
            ordering = _.find sortedBy, (o) -> o.name is propertyName            
            ordering?.order    

    # Removes the given item from this data source.
    #
    # TODO: Define this method in such a way that it will handle server paging
    # better (currently leaves a 'gap', will reshow this item if user visits another
    # page then goes back to the page this item is on).
    remove: (item) ->
        @_loadedItems.remove item

    # Performs a load of this data source, which will set the pageNumber to 1
    # and then, using the `provider` specified on construction, load the
    # items uing the current search parameters (if any), the page size (if `serverPaging`
    # is enabled), the current order, and the page number (i.e. 1).
    load: ->
        currentPageNumber = @pageNumber()

        @pageNumber 1

        # serverPaging enabled means subscription to
        # pageNumber to perform re-load so only execute
        # immediately if not enabled, or if current page number
        # is 1 as then subscription not called.
        if not @_serverPagingEnabled or currentPageNumber is 1
            @_doLoad()

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
        if not @isLastPage()
            @goTo @pageNumber() + 1

    # Goes to the previous page, assuming that either client or server-side paging
    # has been enabled at the current page is not the first one (in which case
    # no changes will be made).
    goToPreviousPage: ->
        if not @isFirstPage()
            @goTo @pageNumber() - 1

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

        # The observable typically bound to in the UI, representing the
        # current `page` of items, which if paging is specified will be the
        # current page as defined by the `pageNumber` observable, or if
        # no paging options have been supplied the loaded items.
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
                
        # Server paging means any operation that would affect the
        # items loaded and currently displayed must result in a load.
        if @options.serverPaging
            @pageNumber.subscribe =>
                @_doLoad()

            @sortBy.subscribe =>
                @_doLoad()
    
    _doLoad: ->
        if _.isArray @options.provider
            return

        loadOptions = _.extend {}, @searchParameters()

        if @_serverPagingEnabled
            loadOptions.pageSize = @options.serverPaging
            loadOptions.pageNumber = Math.ceil @pageNumber() / @clientPagesPerServerPage
        
        if @sortBy()?
            loadOptions.orderBy = @sortBy()

        if _.isEqual loadOptions, @_lastProviderOptions
            return

        @isLoading true

        @options.provider loadOptions, ((loadedData) =>
            @_setData loadedData
            @_lastProviderOptions = loadOptions

            @isLoading false
        ), @

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
            items = _.chain(items).map(@options.map).compact().value()

        @_loadedItems items
        @_hasLoadedOnce = true
    