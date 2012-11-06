(basicMethodTests = (methodName, httpMethod) ->
    describe methodName, ->
        describe 'success', ->
            beforeEach ->
                @path = '/Templates/Users List'
                @response = "My HTML Response"
                @request = bo.ajax.url(@path)[methodName]()

                @doneSpy = @spy()
                @failSpy = @spy()
                
                @request.done @doneSpy
                @request.fail @failSpy

                @server.respondWith httpMethod, @path, [200, { "Content-Type": "text/html" }, @response]
                @server.respond()

            it 'should return a promise to attach events to', ->
                expect(@request).toBeAPromise()
                
            it 'should resolve promise with response from server if response is 200', ->
                expect(@doneSpy).toHaveBeenCalledWith @response
                
            it 'should include X-Requested-With header with value of XMLHttpRequest', ->
                expect(@server.requests[0].requestHeaders['X-Requested-With']).toBe 'XMLHttpRequest'

            it 'should raise an ajaxRequestSent message', ->
                expect("ajaxRequestSent:#{@path}").toHaveBeenPublishedWith
                    path: @path
                    method: httpMethod

            it 'should raise an ajaxResponseReceived message', ->
                expect("ajaxResponseReceived:success:#{@path}").toHaveBeenPublishedWith
                    path: @path
                    method: httpMethod
                    response: @response
                    status: 200
                    success: true
                
            it 'should not fail promise with response from server if response is 200', ->
                expect(@failSpy).toHaveNotBeenCalled()

        describe 'success - JSON returned', ->
            beforeEach ->
                @path = '/Users/Managers'
                @responseObject = [{ id: 132, name: 'Mr John Smith' }]
                @responseObjectAsString = JSON.stringify @responseObject
                @request = bo.ajax.url(@path)[methodName]()

                @doneSpy = @spy()
                
                @request.done @doneSpy

                @server.respondWith httpMethod, @path, [200, { "Content-Type": "application/json" }, @responseObjectAsString]
                @server.respond()

            it 'should resolve promise with parsed JSON', ->
                expect(@doneSpy).toHaveBeenCalledWith @responseObject

        describe 'listening for all requests - all successful', ->
            beforeEach ->
                @requests = [
                    { path: '/Users/Managers', response: [{ id: 132, name: 'Mr John Smith' }]}
                    { path: '/Users/Actions', response: ['Delete',' Suspend'] }
                ]

                @aggregatePromise = bo.ajax.listen =>                    
                    for r in @requests
                        r.promise = bo.ajax.url(r.path)[methodName]()
                        r.doneSpy = @spy()

                        r.promise.done r.doneSpy
                
                @aggregateDoneSpy = @spy()                 
                @aggregatePromise.done @aggregateDoneSpy

                for r in @requests
                    @server.respondWith httpMethod, r.path, [200, { "Content-Type": "application/json" }, JSON.stringify r.response]
                
                @server.respond()

                @requestOutsideOfDetection = bo.ajax.url('/OutsideDetectionPath')[methodName]()
                @requestOutsideOfDetectionDoneSpy = @spy()
                @requestOutsideOfDetection.done @requestOutsideOfDetectionDoneSpy

                # Simulate a request ending after listened for requests do.
                @server.respondWith httpMethod, '/OutsideDetectionPath', [200, { "Content-Type": "application/json" }, JSON.stringify r.response]
                @server.respond()                

            it 'should return a promise to attach listeners to', ->
                expect(@aggregatePromise).toBeAPromise()

            it 'should resolve aggregate after all detected requests', ->
                expect(@aggregateDoneSpy).toHaveBeenCalledAfter @requests[0].doneSpy
                expect(@aggregateDoneSpy).toHaveBeenCalledAfter @requests[1].doneSpy

            it 'should not wait for requests initiated outside of listen callback', ->
                expect(@aggregateDoneSpy).toHaveBeenCalledBefore @requestOutsideOfDetectionDoneSpy

            it 'should resolve aggregate with all responses', ->
                expect(@aggregateDoneSpy).toHaveBeenCalledWith @requests[0].response, @requests[1].response

        describe 'failure, with failure handlers added', ->
            beforeEach ->
                @path = '/Users/List'
                @request = bo.ajax.url(@path)[methodName]()
                @response = "Failed"

                @doneSpy = @spy()
                @failSpy = @spy()
                
                @request.done @doneSpy
                @request.fail @failSpy

                @server.respondWith httpMethod, @path, [500, { "Content-Type": "text/html" }, @response]
                @server.respond()
                
            it 'should not resolve promise with response from server if response is 500', ->
                expect(@doneSpy).toHaveNotBeenCalled()

            it 'should raise an ajaxRequestSent message', ->
                expect("ajaxRequestSent:#{@path}").toHaveBeenPublishedWith
                    path: @path
                    method: httpMethod

            it 'should raise an ajaxResponseReceived message', ->
                expect("ajaxResponseReceived:failure:#{@path}").toHaveBeenPublishedWith
                    path: @path
                    method: httpMethod
                    responseText: @response
                    status: 500
                    success: false
                
            it 'should fail promise with response from server if response is not 200', ->
                expect(@failSpy).toHaveBeenCalled()

            it 'should not publish ajaxResponseFailureUnhandled', ->
                expect("ajaxResponseFailureUnhandled:#{@path}").toHaveNotBeenPublished()
        
        describe 'failure with no fail handlers added', ->
            beforeEach ->
                @path = '/Users/List'
                @request = bo.ajax.url(@path)[methodName]()
                @response = "Failed"

                @server.respondWith httpMethod, @path, [500, { "Content-Type": "text/html" }, @response]
                @server.respond()

            it 'should publish ajaxResponseFailureUnhandled', ->
                expect("ajaxResponseFailureUnhandled:#{@path}").toHaveBeenPublishedWith
                    path: @path
                    method: httpMethod
                    responseText: @response
                    status: 500
                    success: false
)

describe 'ajax', ->
    basicMethodTests 'get', 'GET'
    basicMethodTests 'post', 'POST'
    basicMethodTests 'put', 'PUT'
    basicMethodTests 'delete', 'DELETE'
    basicMethodTests 'head', 'HEAD'

    describe 'POST specific', ->
        it 'should POST "values"', ->
            # TODO: How should this be tested properly?
            @request = bo.ajax.url('/AUrl')
                .data({ id: 342 })
                .post()
