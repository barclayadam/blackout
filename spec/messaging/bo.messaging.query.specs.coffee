describe 'Messaging - Queries', ->
    describe 'Executing a query', ->
        beforeEach ->
            bo.messaging.queryUrlTemplate = 'ExecuteQuery/{name}/?values={values}'

            @promise = bo.messaging.query 'My Query', { id: 3456 }

            @successCallback = @spy()
            @promise.then @successCallback

            @failureCallback = @spy()
            @promise.fail @failureCallback

        describe 'that succeeds', ->
            it 'should resolve the promise with the result, using URL with replaced values', ->
                @server.respondWith "GET", 'ExecuteQuery/My Query/?values=' + (encodeURIComponent '{"id":3456}'), [200, { "Content-Type": "application/json" },'{ "resultProperty": 5 }']
                @server.respond() 

                expect(@successCallback).toHaveBeenCalledWith { resultProperty: 5 }
                
        describe 'that fails', ->
            it 'should reject the promise', ->
                @server.respondWith "GET", 'ExecuteQuery/My Query/?values=' + (encodeURIComponent '{"id":3456}'), [500, { "Content-Type": "application/json" },'{}']
                @server.respond() 

                expect(@failureCallback).toHaveBeenCalled()