describe 'RecordCount', ->
	describe 'When bound to a non-paged data source', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<span id="record-count" data-bind="recordCount: ds" />'
			@recordCount = @fixture.find("#record-count")

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should display the total number of items', ->
			expect(@recordCount.text()).toEqual '10'

	describe 'When bound to a paged data source with a single page', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 10
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<span id="record-count" data-bind="recordCount: ds" />'
			@recordCount = @fixture.find("#record-count")

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should display the total number of items', ->
			expect(@recordCount.text()).toEqual '10'

	describe 'When bound to a paged data source with two pages', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 5
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<span id="record-count" data-bind="recordCount: ds" />'
			@recordCount = @fixture.find("#record-count")

			@applyBindingsToHtmlFixture { ds: @dataSource }

		describe 'When currently showing first page', ->
			beforeEach ->
				@dataSource.goTo 1

		it 'should display the total number of items', ->
			expect(@recordCount.text()).toEqual '10'

		describe 'When currently showing second page', ->
			beforeEach ->
				@dataSource.goTo 2	

		it 'should display the total number of items', ->
			expect(@recordCount.text()).toEqual '10'


	describe 'When bound to a paged data source with more 20 pages', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 1
				provider: _.range(0, 20)

			@setHtmlFixture '<span id="record-count" data-bind="recordCount: ds" />'
			@recordCount = @fixture.find("#record-count")

			@applyBindingsToHtmlFixture { ds: @dataSource }

		describe 'When currently showing first page', ->
			beforeEach ->
				@dataSource.goTo 1

		it 'should display the total number of items', ->
			expect(@recordCount.text()).toEqual '20'

		describe 'When currently showing last page', ->
			beforeEach ->
				@dataSource.goTo 20

		it 'should display the total number of items', ->
			expect(@recordCount.text()).toEqual '20'

		describe 'When currently showing mid-way page', ->
			beforeEach ->
				@dataSource.goTo 10

		it 'should display the total number of items', ->
			expect(@recordCount.text()).toEqual '20'