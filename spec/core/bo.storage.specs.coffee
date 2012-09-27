createStorageSpecs = (type) ->
	->
		storage = window[type + 'Storage']

		describe 'with no items', ->
			it 'should have a length of 0', ->
				expect(storage.length).toEqual 0

		describe 'with single, simple, item added', ->
			beforeEach ->
				storage.setItem 'myKey', 'myValue'

			it 'should have a length of 1', ->
				expect(storage.length).toEqual 1

			it 'should allow getting the item', ->
				expect(storage.getItem('myKey')).toEqual 'myValue'

			it 'should allow clearing the storage', ->
				storage.clear()

				expect(storage.getItem('myKey')).toBe null

		describe 'with single, complex, item added', ->
			beforeEach ->
				# To mimic real API, only strings supported
				storage.setItem 'myKey', JSON.stringify { aProperty: 'myValue' }

			it 'should have a length of 1', ->
				expect(storage.length).toEqual 1

			it 'should allow getting the item', ->
				expect(storage.getItem('myKey')).toEqual JSON.stringify { aProperty: 'myValue' }

			it 'should allow clearing the storage', ->
				storage.clear()

				expect(storage.getItem('myKey')).toBe null

		describe 'with extender for simple property', ->
			extensions = {}
			extensions[type + 'Storage'] = 'myKey'

			describe 'with no existing data in storage', ->				
				beforeEach ->
					@observable = ko.observable('myValue').extend extensions

				it 'should not override the existing value on creation', ->
					expect(@observable()).toEqual 'myValue'
					
				it 'should store the value in storage when observable changes', ->
					@observable 123456

                    # Create new observable to load data form storage to check.
					newObservable = ko.observable().extend extensions
					expect(newObservable()).toEqual 123456

			describe 'with empty string (crashes IE8 storing empty string in storage)', ->				
				beforeEach ->
					@observable = ko.observable('').extend extensions

				it 'should not override the existing value on creation', ->
					expect(@observable()).toEqual ''

			describe 'with existing data in storage', ->
				beforeEach ->
					# Create an observable and set its value to store.
					existing = ko.observable().extend extensions
					existing 'myValue'

					@observable = ko.observable('a value to override').extend extensions

				it 'should override the existing value on creation', ->
					expect(@observable()).toEqual 'myValue'
					
				it 'should store the value in storage when observable changes', ->
					@observable 'myNewValue'

					newObservable = ko.observable().extend extensions
					expect(newObservable()).toEqual 'myNewValue'

		describe 'with extender for complex property', ->
			extensions = {}
			extensions[type + 'Storage'] = 'myKey'

			describe 'with no existing data in storage', ->
				beforeEach ->
					@observable = ko.observable({ aProperty: 'myValue' }).extend extensions

				it 'should not override the existing value on creation', ->
					expect(@observable()).toEqual { aProperty: 'myValue' }
					
				it 'should store the value in storage when observable changes', ->
					@observable { aProperty: 'anotherValue' }

                    # Create new observable to load data form storage to check.
					newObservable = ko.observable().extend extensions
					expect(newObservable()).toEqual aProperty: 'anotherValue'

			describe 'with existing data in storage', ->
				beforeEach ->
					# Create an observable and set its value to store.
					existing = ko.observable().extend extensions
					existing aProperty: 'myValue'

					@observable = ko.observable(aProperty: 'a value to override').extend extensions

				it 'should override the existing value on creation', ->
					expect(@observable()).toEqual { aProperty: 'myValue' }
					
				it 'should store the value in storage when observable changes', ->
					@observable { aProperty: 'anotherValue' }

					newObservable = ko.observable().extend extensions
					expect(newObservable()).toEqual aProperty: 'anotherValue'

describe 'Storage', ->
	describe 'localStorage', createStorageSpecs 'local'
	describe 'sessionStorage', createStorageSpecs 'session'
