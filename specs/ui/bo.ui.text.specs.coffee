describe 'Text', ->
	describe 'When bound value is empty', ->
		beforeEach ->
			@value = ko.observable()
			@setHtmlFixture '<span id="output-value" data-bind="text: value, defaultValue: 'not set'" />'

		it 'should display the default value', ->
			expect(@pagerSummary.find("#output-value").text()).toEqual 'not set'

	describe 'When bound value is not empty', ->
		beforeEach ->
			@value = ko.observable('value set')
			@setHtmlFixture '<span id="output-value" data-bind="text: value, defaultValue: 'not set'" />'

		it 'should display the bound value', ->
			expect(@pagerSummary.find("#output-value").text()).toEqual 'value set'