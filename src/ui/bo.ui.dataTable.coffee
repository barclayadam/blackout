class bo.DataTable
    defaultOptions =
        selectable: true

    constructor: (@dataSource, options = defaultOptions) ->
        if dataSource.selectedItem is undefined
            dataSource.selectedItem = ko.observable()
            dataSource.focusedItem = ko.observable()

            if ko.isObservable options.selected
                bo.utils.joinObservables dataSource.selectedItem, options.selected

        @selectedItem = dataSource.selectedItem
        @focusedItem = dataSource.focusedItem

        @options = _.defaults options, defaultOptions

        # Ensure that when selection is made focus is on that
        # item.
        @selectedItem.subscribe (selected) =>
            if (selected?)
                dataSource.focusedItem selected

        dataSource.subscribe 'pageChanged', =>
            dataSource.selectedItem undefined
            dataSource.focusedItem dataSource.pageItems()[0]

    select: (item) ->
        @dataSource.selectedItem item

    focus: (item) ->
        @dataSource.focusedItem item

    focusNext: ->
        currentIndex = _.indexOf @dataSource.pageItems(), @focusedItem()
        count = @dataSource.pageItems().length

        if currentIndex < (count - 1)
            @focusedItem @dataSource.pageItems()[currentIndex + 1]
    
    focusPrevious: ->
        currentIndex = _.indexOf @dataSource.pageItems(), @focusedItem()

        if currentIndex != 0
            @focusedItem @dataSource.pageItems()[currentIndex - 1]

    selectFocused: ->
        @selectedItem @focusedItem()

# The main binding handler for creating a data table, to be applied to a table element with
# an instance of `bo.DataTable` as the single parameter to the handler.
#
# The dataTable binding handler performs works in tandem with a number of other binding handlers,
# such as `header` for controlling headers (with options such as whether to make a header sortable or
# not), `tableBody`, `tableRow` and `column`.
#
# Expected HTML:
#
# <table data-bind="dataTable: dataTableInViewModel">
#    <thead>
#        <th data-bind="header: 'id', notSortable: true">Id</th>
#        <th data-bind="header: 'name'">Name</th>
#        <th data-bind="header: 'status'">Status</th>
#    </thead>

#    <tbody data-bind="tableBody: true">
#        <tr data-bind="tableRow: true">
#            <td data-bind="column: 'id'" />
#            <td data-bind="column: 'name'" />
#            <td data-bind="column: 'status'" />
#        </tr>
#    </tbody>  
# </table>
ko.bindingHandlers.dataTable =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        dataTable = ko.utils.unwrapObservable valueAccessor()

        if dataTable instanceof bo.DataSource
            dataTable = new bo.DataTable dataTable,
                selectable: allBindingsAccessor().selected?
                selected: allBindingsAccessor().selected

        ko.utils.domData.set element, '$dataTable', dataTable

        ko.utils.toggleDomNodeCssClass element, 'data-table', true
                
        if dataTable.options.selectable is true
            element.tabIndex = 0
            ko.utils.toggleDomNodeCssClass element, 'selectable', true

        ko.bindingHandlers.command.init element, (->
            [
                { callback: dataTable.focusPrevious, keyboard: 'up' },
                { callback: dataTable.focusNext, keyboard: 'down' },
                { callback: dataTable.selectFocused, keyboard: 'space' }
            ]), allBindingsAccessor, dataTable

        ko.bindingHandlers.template.init element, (-> data: dataTable), allBindingsAccessor, viewModel, bindingContext

    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        dataTable = ko.utils.domData.get element, '$dataTable'

        isEmpty = dataTable.dataSource.totalCount() is 0
        emptyTemplate = allBindingsAccessor()['onNoRecords']
        populatedTemplate = allBindingsAccessor()['onRecords']

        dataTable.dataSource.isLoading.subscribe ->
            ko.utils.toggleDomNodeCssClass element, 'is-loading', dataTable.dataSource.isLoading()

        if isEmpty
            ko.utils.emptyDomNode element            
        else
            ko.bindingHandlers.template.update element, (-> data: dataTable), allBindingsAccessor, viewModel, bindingContext

        if emptyTemplate?
            jQuery("##{emptyTemplate}").toggle isEmpty and !dataTable.dataSource.isLoading()
        
        if populatedTemplate?
            jQuery("##{populatedTemplate}").toggle !isEmpty 

# A binding handler that should be applied to the th elements of a data table to provide column sorting
# features.
#
# This binding handler delegates much work to the `columnSort` binding handler, providing a simpler syntax 
# by creating the required data structure (e.g. automatically setting the `dataSource` property) by only requiring
# the name of the column being sorted.       
ko.bindingHandlers.header =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        columnName = ko.utils.unwrapObservable valueAccessor()
        dataTable = viewModel

        ko.utils.toggleDomNodeCssClass element, (bo.utils.toCssClass columnName), true

        if allBindingsAccessor()['notSortable'] is undefined
            ko.bindingHandlers.columnSort.init element, -> { dataSource: dataTable.dataSource, property: columnName }

    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        columnName = ko.utils.unwrapObservable valueAccessor()
        dataTable = viewModel

        if allBindingsAccessor()['notSortable'] is undefined
            ko.bindingHandlers.columnSort.update element, -> { dataSource: dataTable.dataSource, property: columnName }

# Identifies the main table body (the `tbody` element) that contains the template (`tr` > `td`) for each row.
ko.bindingHandlers.tableBody =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        dataTable = viewModel

        ko.bindingHandlers.foreach.init element, (-> dataTable.dataSource.pageItems), allBindingsAccessor, viewModel, bindingContext

    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        dataTable = viewModel

        ko.bindingHandlers.foreach.update element, (-> dataTable.dataSource.pageItems), allBindingsAccessor, viewModel, bindingContext
             
# Identifies a table row, providing the selection semantics of data tables, should the `selectable`
# option of the data table be set to `true` (the default).
ko.bindingHandlers.tableRow =
    init: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        dataTable = bindingContext['$parent']

        if dataTable.options.selectable is true
            ko.utils.registerEventHandler element, 'click', ->
                dataTable.selectedItem viewModel

    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        dataTable = bindingContext['$parent']

        if dataTable.options.selectable is true
            isSelected = dataTable.selectedItem() is viewModel
            isFocused = dataTable.focusedItem() is viewModel

            ko.utils.toggleDomNodeCssClass element, 'selected', isSelected
            ko.bindingHandlers.tabIndex.update element, -> isFocused 

        isEven = (bindingContext['$index']() + 1) % 2 is 0
        
        ko.utils.toggleDomNodeCssClass element, 'even', isEven
        ko.utils.toggleDomNodeCssClass element, 'odd', !isEven

ko.bindingHandlers.column =
    update: (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) ->
        columnName = ko.utils.unwrapObservable valueAccessor()

        ko.utils.toggleDomNodeCssClass element, (bo.utils.toCssClass columnName), true
        ko.bindingHandlers.text.update element, (-> viewModel[columnName]), allBindingsAccessor, viewModel, bindingContext