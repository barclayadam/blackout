#reference "../../js/blackout/bo.messaging.coffee"

describe 'Messaging', ->
    describe 'Command:', ->
        describe 'With a newly created command', ->
            it 'has a name property', ->
                command = new bo.Command 'Command1'
                expect(command.name).toEqual 'Command1'

            it 'should create observables for each property / value pair passed in constructor', ->
                command = new bo.Command 'Command1', { myProperty: 'This value' }

                expect(command.myProperty).toBeObservable()
                expect(command.myProperty()).toEqual 'This value'

            it 'should publish a command created message', ->
                # Arrange
                commandCreatedSpy = @spy()
                bo.bus.subscribe 'commandCreated:Command1', commandCreatedSpy

                # Act
                command = new bo.Command 'Command1'

                # Assert
                expect(commandCreatedSpy).toHaveBeenCalledWith command

            it 'should have a properties function that returns all property key / value pairs as plain values', ->
                # Arrange
                command = new bo.Command 'Command1', { property: 'My value' }

                # Act
                properties = command.properties()

                # Assert
                expect(properties).toEqual { 'property': 'My value' }

    describe 'When executing a single query', ->
        beforeEach ->       
            bo.messaging.config.query.url = "ExecuteMyQuery/?query.name=$queryName&query.values=$queryValues"
            bo.messaging.config.query.optionsParameterName = "myOptions"

            @promise = bo.messaging.query 'My Query', { id: 3456 }

            @successCallback = @spy()
            @promise.then @successCallback

            @failureCallback = @spy()
            @promise.fail @failureCallback
                
        describe 'that succeeds', ->
            beforeEach ->  
                @server.respondWith "GET", '/ExecuteMyQuery/?query.name=My Query&query.values={"id":3456}', [200, { "Content-Type": "application/json" },'{ "resultProperty": 5 }']
                @server.respond()   

            it 'should resolve the promise with the result', ->
                expect(@successCallback).toHaveBeenCalledWith { resultProperty: 5 }

            it 'should publish a queryExecuting message', ->
                expect("queryExecuting:My Query").toHaveBeenPublishedWith
                    name: 'My Query'
                    values: { id: 3456 }          

            it 'should publish a queryResultReceived message', ->
                expect("queryResultReceived:My Query").toHaveBeenPublishedWith
                    name: 'My Query'
                    values: { id: 3456 }
                    result: { resultProperty: 5 }
                    hasFailed: false

            it 'should publish a queryExecuted message', ->
                expect("queryExecuted:My Query").toHaveBeenPublishedWith
                    name: 'My Query'
                    values: { id: 3456 }
                    result: { resultProperty: 5 }
                    hasFailed: false
                
        describe 'that fails', ->
            beforeEach ->  
                @server.respondWith "GET", "/ExecuteMyQuery/?query.name=My Query&query.values={}", [500, { "Content-Type": "application/json" },'{}']
                @server.respond()  

            it 'should reject the promise', ->
                expect(@failureCallback).toHaveBeenCalled()

            it 'should publish a queryExecuting message', ->
                expect("queryExecuting:My Query").toHaveBeenPublishedWith
                    name: 'My Query'
                    values: { id: 3456 }              

            it 'should publish a queryResultReceived message indicating failure', ->
                expect("queryResultReceived:My Query").toHaveBeenPublishedWith
                    name: 'My Query'
                    values: { id: 3456 }
                    result: undefined
                    hasFailed: true            

            it 'should publish a queryFailed message indicating failure', ->
                expect("queryFailed:My Query").toHaveBeenPublishedWith
                    name: 'My Query'
                    values: { id: 3456 }
                    result: undefined
                    hasFailed: true

    describe 'When executing a single command', ->
        beforeEach ->       
            bo.messaging.config.command.url = "DoCommand/$commandName"
            bo.messaging.config.command.optionsParameterName = "myOptions"

            @command = new bo.Command 'My Command', { id: 3456 }

            @promise = bo.messaging.command @command

            @successCallback = @spy()
            @promise.then @successCallback

            @failureCallback = @spy()
            @promise.fail @failureCallback
                
        describe 'that succeeds', ->
            beforeEach ->  
                @server.respondWith "POST", "/DoCommand/My Command", [200, { "Content-Type": "application/json" },'{ "resultProperty": 5}']
                @server.respond()   

            it 'should resolve the promise with the result', ->
                expect(@successCallback).toHaveBeenCalledWith { resultProperty: 5 }

            it 'should publish a commandExecuting message', ->
                expect("commandExecuting:My Command").toHaveBeenPublishedWith
                    name: 'My Command'
                    values: { id: 3456 }          

            it 'should publish a commandResultReceieved message', ->
                expect("commandResultReceived:My Command").toHaveBeenPublishedWith
                    name: 'My Command'
                    values: { id: 3456 },
                    result: { resultProperty: 5 },
                    hasFailed: false

            it 'should publish a commandExecuted message', ->
                expect("commandExecuted:My Command").toHaveBeenPublishedWith
                    name: 'My Command', 
                    values: { id: 3456 }
                    result: { resultProperty: 5 },
                    hasFailed: false
                
        describe 'that fails', ->
            beforeEach ->  
                @server.respondWith "POST", "/DoCommand/My Command", [500, { "Content-Type": "application/json" },'{}']
                @server.respond()  

            it 'should reject the promise', ->
                expect(@failureCallback).toHaveBeenCalled()

            it 'should publish a commandExecuting message', ->
                expect("commandExecuting:My Command").toHaveBeenPublishedWith
                    name: 'My Command'
                    values: { id: 3456 }              

            it 'should publish a commandResultReceieved message indicating failure', ->
                expect("commandResultReceived:My Command").toHaveBeenPublishedWith
                    name: 'My Command'
                    values: { id: 3456 },
                    result: undefined,
                    hasFailed: true            

            it 'should publish a commandFailed message indicating failure', ->
                expect("commandFailed:My Command").toHaveBeenPublishedWith
                    name: 'My Command'
                    values: { id: 3456 },
                    result: undefined,
                    hasFailed: true

    describe 'When executing a batch of commands', ->
        it 'Should make a POST request to the batch URL with all commands', ->
            bo.messaging.config.command.batchUrl = "SendBatch"
            bo.messaging.config.command.optionsParameterName = "myOptions"

            @server.respondWith "POST", "/SendBatch", [200, { "Content-Type": "application/json" },'{}']

            callback = @spy()

            command1 = new bo.Command 'My Command'
            command1.id = 3456
            
            command2 = new bo.Command 'My Command 2'
            command2.id = 3456

            # Act
            promise = bo.messaging.commands [command1, command2]
            promise.then callback

            @server.respond()

            # Assert
            expect(callback).toHaveBeenCalled()