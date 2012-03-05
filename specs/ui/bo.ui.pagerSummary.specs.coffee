describe 'PagerSummary', ->
	describe 'When bound to a non-paged data source', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<span id="pager-summary" data-bind="pagerSummary: ds" />'
			@pagerSummary = @fixture.find("#pager-summary")

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should display the correct current page', ->
			expect(@pagerSummary.find("#current-page").text()).toEqual '1'

		it 'should display the correct page count', ->
			expect(@pagerSummary.find("#page-count").text()).toEqual '1'

	describe 'When bound to a paged data source with a single page', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 10
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<span id="pager-summary" data-bind="pagerSummary: ds" />'
			@pagerSummary = @fixture.find("#pager-summary")

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should display the correct current page', ->
			expect(@pagerSummary.find("#current-page").text()).toEqual '1'
			
		it 'should display the correct page count', ->
			expect(@pagerSummary.find("#page-count").text()).toEqual '1'

	describe 'When bound to a paged data source with two pages', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 5
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<span id="pager-summary" data-bind="pagerSummary: ds" />'
			@pagerSummary = @fixture.find("#pager-summary")

			@applyBindingsToHtmlFixture { ds: @dataSource }
				
		it 'should display the correct page count', ->
			expect(@pagerSummary.find("#page-count").text()).toEqual '2'

		describe 'When currently showing first page', ->
			beforeEach ->
				@dataSource.goTo 1

			it 'should display the correct current page', ->
				expect(@pagerSummary.find("#current-page").text()).toEqual '1'

		describe 'When currently showing second page', ->
			beforeEach ->
				@dataSource.goTo 2	

			it 'should display the correct current page', ->
				expect(@pagerSummary.find("#current-page").text()).toEqual '2'

	describe 'When bound to a paged data source with 3 pages', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 10
				provider: _.range(0, 30)

			@setHtmlFixture '<span id="pager-summary" data-bind="pagerSummary: ds" />'
			@pagerSummary = @fixture.find("#pager-summary")

			@applyBindingsToHtmlFixture { ds: @dataSource }
				
		it 'should display the correct page count', ->
			expect(@pagerSummary.find("#page-count").text()).toEqual '3'

		describe 'When currently showing first page', ->
			beforeEach ->
				@dataSource.goTo 1

			it 'should display the correct current page', ->
				expect(@pagerSummary.find("#current-page").text()).toEqual '1'

		describe 'When currently showing last page', ->
			beforeEach ->
				@dataSource.goTo 3

			it 'should display the correct current page', ->
				expect(@pagerSummary.find("#current-page").text()).toEqual '3'

		describe 'When currently showing mid-way page', ->
			beforeEach ->
				@dataSource.goTo 2

			it 'should display the correct current page', ->
				expect(@pagerSummary.find("#current-page").text()).toEqual '2'