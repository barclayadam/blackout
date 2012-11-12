describe 'Messaging - Commands', ->
    describe 'Executing a command (low-level)', ->
        beforeEach ->
            bo.messaging.commandUrlTemplate = 'ExecuteCommand/{name}'

            @promise = bo.messaging.command 'My Command', { id: 3456 }

            @successCallback = @spy()
            @promise.then @successCallback

            @failureCallback = @spy()
            @promise.fail @failureCallback

        describe 'that succeeds', ->
            it 'should resolve the promise with the result, using URL with replaced name', ->
                @server.respondWith "POST", "ExecuteCommand/My Command", [200, { "Content-Type": "application/json" },'{ "resultProperty": 5}']
                @server.respond()  

                expect(@successCallback).toHaveBeenCalledWith { resultProperty: 5 }
                
        describe 'that fails', ->
            it 'should reject the promise', ->
                @server.respondWith "POST", "ExecuteCommand/My Command", [500, { "Content-Type": "application/json" },'{}']
                @server.respond()  

                expect(@failureCallback).toHaveBeenCalled()

    describe 'Manipulating a Command', ->
        beforeEach ->
            @command = new bo.messaging.Command 'My Command', { id: 3456, name: 'My Name' }
            @command.extraProperty = 4

        it 'should only include values from defaultValues in JSON', ->
            expect(JSON.parse(JSON.stringify(@command))).toEqual { id: 3456, name: 'My Name' }

        it 'should be validatable', ->
            expect(@command.validate).toBeAFunction()

        it 'should have directly accessible observables for values defined in constructor', ->
            expect(@command.id()).toEqual 3456
            expect(@command.name()).toEqual 'My Name'

    describe 'Executing a Command', ->
        beforeEach ->
            bo.messaging.commandUrlTemplate = 'ExecuteCommand/{name}'

            @command = new bo.messaging.Command 'My Command', { id: 3456 }
            @promise = @command.execute()

            @successCallback = @spy()
            @promise.then @successCallback

            @failureCallback = @spy()
            @promise.fail @failureCallback

        describe 'that succeeds', ->
            it 'should resolve the promise with the result, using URL with replaced name', ->
                @server.respondWith "POST", "ExecuteCommand/My Command", [200, { "Content-Type": "application/json" },'{ "resultProperty": 5}']
                @server.respond()  

                expect(@successCallback).toHaveBeenCalledWith { resultProperty: 5 }
                
        describe 'that fails', ->
            it 'should reject the promise', ->
                @server.respondWith "POST", "ExecuteCommand/My Command", [500, { "Content-Type": "application/json" },'{}']
                @server.respond()  

                expect(@failureCallback).toHaveBeenCalled()