describe 'Pager', ->
	describe 'When bound to a non-paged data source', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<div data-bind="pager: ds" />'
			@pager = @fixture.children().first()

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should not render any content', ->
			expect(@pager).toBeEmpty()

	describe 'When bound to a paged data source with a single page', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 10
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<div data-bind="pager: ds" />'
			@pager = @fixture.children().first()

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should have first page link', ->
			expect(@pager.find('.goto-first')).toExist()		

		it 'should disable the first page link', ->	
			expect(@pager.find('.goto-first')).toBeDisabled()

		it 'should have previous link', ->
			expect(@pager.find('.goto-previous')).toExist()		

		it 'should disable the previous link', ->	
			expect(@pager.find('.goto-previous')).toBeDisabled()

		it 'should have a single page link', ->
			expect(@pager.find('.page').length).toEqual 1

		it 'should have a single page link that has is-selected class', ->
			expect(@pager.find('.page').first()).toHaveClass 'is-selected'

		it 'should have next page link', ->
			expect(@pager.find('.goto-next')).toExist()		

		it 'should disable the next link', ->	
			expect(@pager.find('.goto-next')).toBeDisabled()

		it 'should have last page link', ->
			expect(@pager.find('.goto-last')).toExist()		

		it 'should disable the last page link', ->	
			expect(@pager.find('.goto-last')).toBeDisabled()

	describe 'When bound to a paged data source with two pages', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 5
				provider: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

			@setHtmlFixture '<div data-bind="pager: ds" />'
			@pager = @fixture.children().first()

			@applyBindingsToHtmlFixture { ds: @dataSource }

		describe 'When currently showing first page', ->
			beforeEach ->
				@dataSource.goTo 1

			it 'should disable the first page link', ->	
				expect(@pager.find('.goto-first')).toBeDisabled()	

			it 'should disable the previous link', ->	
				expect(@pager.find('.goto-previous')).toBeDisabled()

			it 'should have two page links', ->
				expect(@pager.find('.page').length).toEqual 2

			it 'should mark the first page as selected', ->
				expect(@pager.find('.page').first()).toHaveClass 'is-selected'

			it 'should not mark the second page as selected', ->
				expect(@pager.find('.page').eq(1)).toNotHaveClass 'is-selected'

			it 'should enable the next link', ->	
				expect(@pager.find('.goto-next')).toBeEnabled()

			it 'should enable the last page link', ->	
				expect(@pager.find('.goto-last')).toBeEnabled()

		describe 'When currently showing second page', ->
			beforeEach ->
				@dataSource.goTo 2	

			it 'should enable the first page link', ->	
				expect(@pager.find('.goto-first')).toBeEnabled()

			it 'should enable the previous link', ->	
				expect(@pager.find('.goto-previous')).toBeEnabled()

			it 'should have two page links', ->
				expect(@pager.find('.page').length).toEqual 2

			it 'should not mark the first page as selected', ->
				expect(@pager.find('.page').first()).toNotHaveClass 'is-selected'

			it 'should mark the second page as selected', ->
				expect(@pager.find('.page').eq(1)).toHaveClass 'is-selected'

			it 'should disable the next link', ->	
				expect(@pager.find('.goto-next')).toBeDisabled()

			it 'should disable the last page link', ->	
				expect(@pager.find('.goto-last')).toBeDisabled()

	describe 'When bound to a paged data source with more pages (20) than a maximum (10)', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				clientPaging: 1
				provider: _.range(0, 20)

			@setHtmlFixture '<div data-bind="pager: ds, maximumPagesShown: 10" />'
			@pager = @fixture.children().first()

			@applyBindingsToHtmlFixture { ds: @dataSource }

		describe 'When currently showing first page', ->
			beforeEach ->
				@dataSource.goTo 1

			it 'should have the first 10 pages shown only', ->
				expect(@pager.find('.page').length).toEqual 10

			it 'should start at page 1', ->
				expect(@pager.find('.page').first().text()).toEqual '1'

			it 'should finish on page 10', ->
				expect(@pager.find('.page').last().text()).toEqual '10'

		describe 'When currently showing last page', ->
			beforeEach ->
				@dataSource.goTo 20

			it 'should have the last ten pages shown only', ->
				expect(@pager.find('.page').length).toEqual 10

			it 'should start at page 11', ->
				expect(@pager.find('.page').first().text()).toEqual '11'

			it 'should finish on page 20', ->
				expect(@pager.find('.page').last().text()).toEqual '20'

		describe 'When currently showing mid-way page', ->
			beforeEach ->
				@dataSource.goTo 10

			it 'should have ten pages shown only', ->
				expect(@pager.find('.page').length).toEqual 10

			it 'should start at page 5', ->
				expect(@pager.find('.page').first().text()).toEqual '5'

			it 'should finish on page 14', ->
				expect(@pager.find('.page').last().text()).toEqual '14'
