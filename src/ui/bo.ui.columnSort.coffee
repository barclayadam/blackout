ko.bindingHandlers.columnSort =
	init: (element, viewModelAccessor) ->
		dataSource = viewModelAccessor().dataSource
		property = viewModelAccessor().property
		
		ko.utils.toggleDomNodeCssClass element, 'sortable', true

		ko.utils.registerEventHandler element, 'click', ->
			sortOrder = (dataSource.getPropertingSortOrder property) || 'descending'

			if sortOrder is 'descending'
				dataSource.sortBy "#{property} ascending"
			else
				dataSource.sortBy "#{property} descending"
			

	update: (element, viewModelAccessor) ->
		dataSource = viewModelAccessor().dataSource
		property = viewModelAccessor().property

		sortOrder = dataSource.getPropertingSortOrder property

		ko.utils.toggleDomNodeCssClass element, 'ascending', sortOrder is 'ascending'
		ko.utils.toggleDomNodeCssClass element, 'descending', sortOrder is 'descending'
