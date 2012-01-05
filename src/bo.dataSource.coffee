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
class bo.DataSource
	constructor: (@options) ->
		# An observable property that represents whether or not this data source is
		# currently loading some data (using the specified `provider`).
		@isLoading = ko.observable false

		@_hasLoadedOnce = false
		@_serverPagingEnabled = @options.serverPaging > 0
		@_clientPagingEnabled = @options.clientPaging > 0

		# Stores the items as loaded (e.g. without sorting / paging applied
		# when in client-side only mode).
		@_loadedItems = ko.observableArray()

		# A textual description of the sorting that is currently in-place
		# on this data source, which will be one of:
		# * `ascending` - The items themselves are ordered in ascending order.
		# * `descending` - The items themselves are ordered in descending order.
		# * `myProperty [ascending|descending][, anotherProperty]` - The properties and
		# their (optional) direction that are being ordered.
		@sorting = ko.observable()
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
					@load()
		else
			@searchParameters = ko.observable {}

		@_setupPaging()
		@_setupInitialData()

	# Sorts the items in ascending order, assuming that the items theirselves
	# can be ordered using the less than (<) operator. 
	sort: ->
		if not @_serverPagingEnabled
			@_sortFunction (a, b) -> (b < a) - (a < b)

		@sorting 'ascending'

	# Sorts the items in descending order, assuming that the items theirselves
	# can be ordered using the less than (<) operator.
	sortDescending: ->
		if not @_serverPagingEnabled
			@_sortFunction (a, b) -> ((b < a) - (a < b)) * -1

		@sorting 'descending'

	sortBy: (propertyNames) ->
		if not @_serverPagingEnabled
			properties = _(propertyNames.split(',')).map (p) ->
				indexOfSpace = p.indexOf ' '

				if indexOfSpace > -1
					name: p.substring 0, indexOfSpace
					order: p.substring indexOfSpace + 1
				else
					name: p
					order: 'ascending'

			@_sortFunction (a, b) -> 
				for p in properties
					if a[p.name] > b[p.name]
						return if p.order is 'ascending' then 1 else -1
					
					if a[p.name] < b[p.name]
						return if p.order is 'ascending' then -1 else 1

				0

		@sorting propertyNames

	# Performs a load of this data source, which will set the pageNumber to 1
	# and then, using the `provider` specified on construction, load the
	# items uing the current search parameters (if any), the page size (if `serverPaging`)
	# is enabled and the page number (i.e. 1).
	load: ->
		@pageNumber 1

		# serverPaging enabled means subscription to
		# pageNumber to perform re-load so only execute
		# immediately if not enabled.
		if not @_serverPagingEnabled
			@_doLoad()

    # Goes to the next page, assuming that either client or server-side paging
    # has been enabled at the current page is not the last one (in which case
    # no changes will be made).
	goToNextPage: ->
		@pageNumber @pageNumber() + 1 if not @isLastPage()

    # Goes to the previous page, assuming that either client or server-side paging
    # has been enabled at the current page is not the first one (in which case
    # no changes will be made).
	goToPreviousPage: ->
		@pageNumber @pageNumber() - 1  if not @isFirstPage()

	_setupInitialData: ->
		if @options.provider? and _.isArray @options.provider
			@_setData @options.provider
			@pageNumber 1

	_setupPaging: ->
		@serverPageLastRetrieved = -1
		@clientPagesPerServerPage = @options.serverPaging / (@options.clientPaging || @options.serverPaging)

		@pageSize = ko.observable()
		@pageNumber = ko.observable()
		@totalCount = ko.observable()

		@pageItems = ko.computed =>
			if @_clientPagingEnabled and @_serverPagingEnabled
				adjustedPageNumber = @clientPagesPerServerPage - (@pageNumber() % @clientPagesPerServerPage)

				start = (adjustedPageNumber - 1) * @pageSize()
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
			Math.ceil @totalCount() / @pageSize()

		@pages = ko.computed =>
			if @pageCount() > 0
		        _(_.range(1, @pageCount() + 1)).map (p) =>
	                pageNumber: p
	                isSelected: p is @pageNumber()
	                select: => @pageNumber p
		    else
		    	[]    

		# An observable property that indicates whether the current page 
		# is the first one.
		@isFirstPage = ko.computed =>
			@pageNumber() is 1

		# An observable property that indicates whether the current page 
		# is the last one.
		@isLastPage = ko.computed =>
        	@pageNumber() is @pageCount()
		    	
		if @options.serverPaging
			@pageNumber.subscribe =>
				@_doLoad()
	
	_doLoad: ->
		if @options.provider? and _.isArray @options.provider
			return

		loadOptions = @searchParameters()

		if @_serverPagingEnabled
			loadOptions.pageSize = @options.serverPaging
			loadOptions.pageNumber = Math.round @pageNumber() / @clientPagesPerServerPage

			if loadOptions.pageNumber is @serverPageLastRetrieved
				return
		
		loadOptions.sorting = @sorting() if @sorting()?

		@options.provider loadOptions, (loadedData) =>
			@_setData loadedData

			@serverPageLastRetrieved = loadOptions.pageNumber

	_setData: (loadedData) ->	
		items = []

		if @options.serverPaging
			items = loadedData.items

			@pageSize @options.clientPaging || @options.serverPaging
			@totalCount loadedData.totalCount
		else
			items = loadedData

			@pageSize @options.clientPaging || loadedData.length
			@totalCount loadedData.length

		items = _(items).chain().map(@options.map).compact().value() if @options.map?

		@_loadedItems items
		@_hasLoadedOnce = true
	