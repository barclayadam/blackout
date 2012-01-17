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
				storage.setItem 'myKey', JSON.stringify { aProperty: 'myValue' }

			it 'should have a length of 1', ->
				expect(storage.length).toEqual 1

			it 'should allow getting the item', ->
				expect(storage.getItem('myKey')).toEqual JSON.stringify { aProperty: 'myValue' }

			it 'should allow clearing the storage', ->
				storage.clear()

				expect(storage.getItem('myKey')).toBe null

		describe 'with extender for simple property', ->
			describe 'with no existing data in storage', ->
				beforeEach ->
					extensions = {}
					extensions[type + 'Storage'] = 'myKey'

					@observable = ko.observable('myValue').extend extensions

				it 'should not override the existing value on creation', ->
					expect(@observable()).toEqual 'myValue'
					
				it 'should store the value in storage when observable changes', ->
					@observable 123456

					expect(storage.getItem('myKey')).toEqual '123456'

			describe 'with existing data in storage', ->
				beforeEach ->
					extensions = {}
					extensions[type + 'Storage'] = 'myKey'

					storage.setItem 'myKey', 'myValue'
					@observable = ko.observable().extend extensions

				it 'should override the existing value on creation', ->
					expect(@observable()).toEqual 'myValue'
					
				it 'should store the value in storage when observable changes', ->
					@observable 'myValue'

					expect(storage.getItem('myKey')).toEqual 'myValue'

		describe 'with extender for complex property', ->
			describe 'with no existing data in storage', ->
				beforeEach ->
					extensions = {}
					extensions[type + 'Storage'] = 
						key: 'myKey'
						isObject: true

					@observable = ko.observable({ aProperty: 'myValue' }).extend extensions

				it 'should not override the existing value on creation', ->
					expect(@observable()).toEqual { aProperty: 'myValue' }
					
				it 'should store the value in storage when observable changes', ->
					@observable { aProperty: 'anotherValue' }

					expect(storage.getItem('myKey')).toEqual JSON.stringify { aProperty: 'anotherValue' }

			describe 'with existing data in storage', ->
				beforeEach ->
					extensions = {}
					extensions[type + 'Storage']  = 
						key: 'myKey'
						isObject: true

					storage.setItem 'myKey', JSON.stringify { aProperty: 'myValue' }
					@observable = ko.observable().extend extensions

				it 'should override the existing value on creation', ->
					expect(@observable()).toEqual { aProperty: 'myValue' }
					
				it 'should store the value in storage when observable changes', ->
					@observable { aProperty: 'anotherValue' }

					expect(storage.getItem('myKey')).toEqual JSON.stringify { aProperty: 'anotherValue' }

describe 'Storage', ->
	describe 'localStorage', createStorageSpecs 'local'
	describe 'sessionStorage', createStorageSpecs 'session'
