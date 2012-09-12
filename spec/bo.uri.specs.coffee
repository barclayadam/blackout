describe 'Uri', ->	
	describe 'Complex Full URI', ->
		beforeEach ->
			@input = 'http://domain:8080/path/to/file.html?key=value&arr=value2&arr=value3#myHashValue'
			@uri = new bo.Uri @input

		it 'should parse the scheme', ->
			expect(@uri.scheme).toEqual 'http'

		it 'should parse the host', ->
			expect(@uri.host).toEqual 'domain'

		it 'should parse the port', ->
			expect(@uri.port).toEqual 8080

		it 'should parse the path', ->
			expect(@uri.path).toEqual '/path/to/file.html'

		it 'should parse the fragment', ->
			expect(@uri.fragment).toEqual 'myHashValue'

		it 'should parse the query string', ->
			expect(@uri.query).toEqual 'key=value&arr=value2&arr=value3'

		it 'should create variables from the query string', ->
			expect(@uri.variables['key']).toEqual 'value'
			expect(@uri.variables['arr'][0]).toEqual 'value2'
			expect(@uri.variables['arr'][1]).toEqual 'value3'

		it 'should recreate via toString correctly', ->
			expect(@uri.toString()).toEqual @input

	describe 'URI with encoded characters in path', ->
		describe 'URI created with decode = true', ->
			beforeEach ->
				@input = 'http://domain:8080/path%20to/file.html'
				@uri = new bo.Uri @input, { decode: true }

			it 'should decode the path', ->
				expect(@uri.path).toEqual '/path to/file.html'

		describe 'URI created with decode = false', ->
			beforeEach ->
				@input = 'http://domain:8080/path%20to/file.html'
				@uri = new bo.Uri @input, { decode: false }

			it 'should not decode the path', ->
				expect(@uri.path).toEqual '/path%20to/file.html'

	describe 'Complex relative URI', ->
		beforeEach ->
			@input = '/path/to/file.html?key=value&key1=value2#myHashValue'
			@uri = new bo.Uri @input

		it 'should parse the path', ->
			expect(@uri.path).toEqual '/path/to/file.html'

		it 'should parse the fragment', ->
			expect(@uri.fragment).toEqual 'myHashValue'

		it 'should parse the query string', ->
			expect(@uri.query).toEqual 'key=value&key1=value2'

		it 'should create variables from the query string', ->
			expect(@uri.variables['key']).toEqual 'value'
			expect(@uri.variables['key1']).toEqual 'value2'

		it 'should set the scheme to be falsy', ->
			expect(@uri.scheme).toBeFalsy()

		it 'should set the host to be falsy', ->
			expect(@uri.host).toBeFalsy()

		it 'should set the port to be falsy', ->
			expect(@uri.port).toBeFalsy()
			
		it 'should recreate via toString correctly', ->
			expect(@uri.toString()).toEqual @input

	describe 'Simple URI with no port, query or hash', ->		
		beforeEach ->
			@input = 'http://domain/path/to/file.html'
			@uri = new bo.Uri @input

		it 'should parse the scheme', ->
			expect(@uri.scheme).toEqual 'http'

		it 'should parse the host', ->
			expect(@uri.host).toEqual 'domain'

		it 'should parse the path', ->
			expect(@uri.path).toEqual '/path/to/file.html'

		it 'should set fragment to be falsy', ->
			expect(@uri.fragment).toBeFalsy()

		it 'should set query to be falsy', ->
			expect(@uri.query).toBeFalsy()

		it 'should set variables to empty object', ->
			expect(@uri.variables).toEqual {}

		it 'should recreate via toString correctly', ->
			expect(@uri.toString()).toEqual @input

	describe 'round-tripping variables to query to variables', ->		
		beforeEach ->
			@input = 'http://domain/path/to/file.html'
			@uri = new bo.Uri @input

			@uri.variables['string'] = 'A String Value'
			@uri.variables['int'] = 12345
			@uri.variables['bool'] = false
			@uri.variables['arr'] = ['A String Value', 123]

			@generatedUri = new bo.Uri @uri.toString()

		it 'should handle strings', ->
			expect(@generatedUri.variables['string']).toEqual 'A String Value'

		it 'should handle bools', ->
			expect(@generatedUri.variables['bool']).toEqual false

		it 'should handle numbers', ->
			expect(@generatedUri.variables['int']).toEqual 12345

		it 'should handle arrays', ->
			expect(@generatedUri.variables['arr']).toEqual ['A String Value', 123]

	describe 'cloning a URI', ->
		beforeEach ->
			@input = 'http://domain:8080/path/to/file.html?key=value&arr=value2&arr=value3#myHashValue'			
			@original = new bo.Uri @input
			@clone = @original.clone()

			@clone.host = 'anotherDomain'

		it 'should have copies of all properties', ->
			expect(@clone.scheme).toEqual @original.scheme
			expect(@clone.port).toEqual @original.port
			expect(@clone.path).toEqual @original.path
			expect(@clone.fragment).toEqual @original.fragment
			expect(@clone.query).toEqual @original.query
			expect(@clone.variables).toEqual @original.variables

		it 'should allow setting of properties without affecting original', ->
			expect(@original.host).toEqual 'domain'
			expect(@clone.host).toEqual 'anotherDomain'