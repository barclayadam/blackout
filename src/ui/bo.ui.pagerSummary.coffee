bo.utils.addTemplate 'pagerSummaryTemplate', 
'''<span id="current-page" data-bind="text: pageNumber"></span> of <span id="page-count" data-bind="text: pageCount"></span>'''

ko.bindingHandlers.pagerSummary = 
    init: (element, valueAccessor, allBindingsAccessor) ->
        { "controlsDescendantBindings" : true }

    update: (element, valueAccessor, allBindingsAccessor) ->
        dataSource = valueAccessor()

        throw new Error 'A pagerSummary binding handler must be passed a DataSource as its only parameter.' if not (dataSource instanceof bo.DataSource)

        if dataSource.pagingEnabled
            viewModel = dataSource
        else
            viewModel =
                pageNumber: 1
                pageCount: 1

        ko.renderTemplate 'pagerSummaryTemplate', viewModel, {}, element, 'replaceChildren'
