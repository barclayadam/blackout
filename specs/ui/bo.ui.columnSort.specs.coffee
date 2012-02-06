describe 'Column Sort', ->
	describe 'When bound to a data source with no ordering', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				provider: [
					{ myProperty: 1 }, 
					{ myProperty: 2 }, 
					{ myProperty: 3 }, 
					{ myProperty: 4 }, 
					{ myProperty: 5 }]

			@setHtmlFixture '''<th data-bind="columnSort: { dataSource: ds, property: 'myProperty' }" />'''
			@columnSort = @fixture.children()

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should add sortable class', ->
			expect(@columnSort).toHaveClass 'sortable'

		it 'should not add ascending class', ->
			expect(@columnSort).toNotHaveClass 'ascending'

		it 'should not add ascending class', ->
			expect(@columnSort).toNotHaveClass 'descending'

		it 'should have an aria-role attribute set to none', ->
			expect(@columnSort).toHaveAttr 'aria-sort', 'none'

		describe 'When the user clicks on the column sort element', ->
			beforeEach ->
				@columnSort.click()

			it 'should sort the data source in ascending order', ->
				expect(@dataSource.getPropertySortOrder('myProperty')).toEqual 'ascending'

	describe 'When bound to a data source with ascending ordering', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				provider: [
					{ myProperty: 1 }, 
					{ myProperty: 2 }, 
					{ myProperty: 3 }, 
					{ myProperty: 4 }, 
					{ myProperty: 5 }]

			@dataSource.sortBy 'myProperty ascending'

			@setHtmlFixture '''<th data-bind="columnSort: { dataSource: ds, property: 'myProperty' }" />'''
			@columnSort = @fixture.children()

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should add sortable class', ->
			expect(@columnSort).toHaveClass 'sortable'

		it 'should add ascending class', ->
			expect(@columnSort).toHaveClass 'ascending'

		it 'should have an aria-role attribute set to ascending', ->
			expect(@columnSort).toHaveAttr 'aria-sort', 'ascending'

		it 'should not add descending class', ->
			expect(@columnSort).toNotHaveClass 'descending'

		describe 'When the user clicks on the column sort element', ->
			beforeEach ->
				@columnSort.click()

			it 'should sort the data source in descending order', ->
				expect(@dataSource.getPropertySortOrder('myProperty')).toEqual 'descending'

	describe 'When bound to a data source with descending ordering', ->
		beforeEach ->
			@dataSource = new bo.DataSource
				provider: [
					{ myProperty: 1 }, 
					{ myProperty: 2 }, 
					{ myProperty: 3 }, 
					{ myProperty: 4 }, 
					{ myProperty: 5 }]

			@dataSource.sortBy 'myProperty descending'

			@setHtmlFixture '''<th data-bind="columnSort: { dataSource: ds, property: 'myProperty' }" />'''
			@columnSort = @fixture.children()

			@applyBindingsToHtmlFixture { ds: @dataSource }

		it 'should add sortable class', ->
			expect(@columnSort).toHaveClass 'sortable'

		it 'should not add ascending class', ->
			expect(@columnSort).toNotHaveClass 'ascending'

		it 'should add descending class', ->
			expect(@columnSort).toHaveClass 'descending'

		it 'should have an aria-role attribute set to descending', ->
			expect(@columnSort).toHaveAttr 'aria-sort', 'descending'

		describe 'When the user clicks on the column sort element', ->
			beforeEach ->
				@columnSort.click()

			it 'should sort the data source in ascending order', ->
				expect(@dataSource.getPropertySortOrder('myProperty')).toEqual 'ascending'
