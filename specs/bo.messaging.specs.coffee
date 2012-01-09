#reference "../../js/blackout/bo.messaging.coffee"

describe 'Messaging', ->
    describe 'Command:', ->
        describe 'With an newly created command', ->
            it 'has a name property', ->
                command = new bo.Command 'Command1'
                expect(command.name).toEqual 'Command1'

            it 'should have a modelErrors observable', ->
                command = new bo.Command 'Command1'
                expect(command.modelErrors).toBeObservable()
                expect(command.modelErrors()).toEqual {}

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

        describe 'With a command that has property values set', ->
            it 'has a properties function that returns all property key / value pairs', ->
                # Arrange
                command = new bo.Command 'Command1'
                command.property = "My Value"

                # Act
                properties = command.properties()

                # Assert
                expect(properties).toEqual { 'property': 'My Value' }

    it 'Has a default processOptions function which returns the same options passed', ->
        options = { key: 'Some Value' }
        processedOptions = bo.messaging.processOptions options

        expect(processedOptions).toEqual options

    describe 'When executing a query', ->
        it 'Makes a GET request to the query URL with name of query', ->
            # Arrange			
            bo.messaging.config.query.url = "/ExecuteMyQuery/?query.name=$queryName&query.values=$queryValues"
            bo.messaging.config.query.optionsParameterName = "myOptions"

            @server.respondWith "GET", "/ExecuteMyQuery/?query.name=My Query&query.values={}", [200, { "Content-Type": "application/json" },'{}']

            callback = @spy()

            # Act
            promise = bo.messaging.query 'My Query'
            promise.then callback

            @server.respond()

            # Assert
            expect(callback).toHaveBeenCalled()

        it 'Should publish a message with the query on successful completion of the query', ->
            # Arrange
            bo.messaging.config.query.url = "/ExecuteMyQuery/?query.name=$queryName&query.values=$queryValues"
            bo.messaging.config.query.optionsParameterName = "myOptions"

            @server.respondWith "GET", "/ExecuteMyQuery/?query.name=My Query&query.values={}", [200, { "Content-Type": "application/json" },'{}']

            # Act
            bo.messaging.query 'My Query'
            @server.respond()

            # Assert
            expect("queryExecuted:My Query").toHaveBeenPublishedWith
                name: 'My Query'
                options: {}

    describe 'When executing a command', ->
        it 'Makes a POST request to the command URL with name of command', ->
            # Arrange			
            bo.messaging.config.command.url = "/DoCommand/$commandName"
            bo.messaging.config.command.optionsParameterName = "myOptions"

            @server.respondWith "POST", "/DoCommand/My Command", [200, { "Content-Type": "application/json" },'{}']

            callback = @spy()

            command = new bo.Command 'My Command'
            command.id = 3456

            # Act
            promise = bo.messaging.command command
            promise.then callback

            @server.respond()

            # Assert
            expect(callback).toHaveBeenCalled()

        it 'Makes a POST request to the batch URL with all commands', ->
            bo.messaging.config.command.batchUrl = "/SendBatch"
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

        it 'Should publish a message on successful completion of the command', ->
            # Arrange
            bo.messaging.config.command.url = "/DoCommand/$commandName"
            bo.messaging.config.command.optionsParameterName = "myOptions"

            @server.respondWith "POST", "/DoCommand/My Command", [200, { "Content-Type": "application/json" },'{}']

            # Act
            bo.messaging.command  new bo.Command 'My Command'

            @server.respond()

            # Assert
            expect("commandExecuted:My Command").toHaveBeenPublishedWith
                name: 'My Command', 
                options: {}
