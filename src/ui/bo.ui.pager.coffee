bo.utils.addTemplate 'pagerPageLinkTemplate', 
				     '''<li data-bind="text: pageNumber, click: select, css: { 'is-selected': isSelected, 'page': true }"></li>'''

bo.utils.addTemplate 'pagerTemplate', 
'''<div class="pager">
    <ol class="previousLinks">
	    <li class="goto-first" data-bind="click: goToFirstPage, enable: !isFirstPage()">First</li>
	    <li class="goto-previous" data-bind="click: goToPreviousPage, enable: !isFirstPage()">Previous</li>
	</ol>

    <ol class="pageLinks" data-bind="template: { foreach: pages, name: 'pagerPageLinkTemplate' }"></ol>

    <ol class="nextLinks">
	    <li class="goto-next" data-bind="enable: !isLastPage(), click: goToNextPage">Next</li>
	    <li class="goto-last" data-bind="enable: !isLastPage(), click: goToLastPage">Last</li>
	</ol>
   </div>'''

class PagerModel
	constructor: (@dataSource, maximumPagesShown) ->
        @isFirstPage = @dataSource.isFirstPage
        @isLastPage = @dataSource.isLastPage

        @goToFirstPage = ->
            @dataSource.goToFirstPage()

        @goToPreviousPage = ->
                @dataSource.goToPreviousPage()

        @goToNextPage = ->
            @dataSource.goToNextPage()

        @goToLastPage = ->
            @dataSource.goToLastPage()

        @pages = ko.computed =>
            if @dataSource.pageCount() > 0
                startPage = @dataSource.pageNumber() - (maximumPagesShown / 2)
                startPage = Math.max 1, Math.min dataSource.pageCount() - maximumPagesShown + 1, startPage

                endPage = startPage + maximumPagesShown
                endPage = Math.min endPage, @dataSource.pageCount() + 1

                pages = _.range startPage, endPage

                _(pages).map (p) =>
                    pageNumber: p
                    isSelected: p is @dataSource.pageNumber()
                    select: => @dataSource.pageNumber p
            else
                []    

ko.bindingHandlers.pager = 
    init: (element, valueAccessor, allBindingsAccessor) ->
        dataSource = valueAccessor()
        maximumPagesShown = allBindingsAccessor().maximumPagesShown ? 10

        if dataSource.pagingEnabled is true
        	ko.renderTemplate 'pagerTemplate', new PagerModel(dataSource, maximumPagesShown), {}, element, 'replaceChildren'

        	{ "controlsDescendantBindings" : true }