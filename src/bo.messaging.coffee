#reference "bo.coffee"
#reference "bo.utils.coffee"

class bo.Command  
    constructor: (@name, values = {}) ->
        @_definedProperties = {}

        for key, value of values
            @_definedProperties[key] = bo.utils.asObservable value
            @[key] = @_definedProperties[key]
            
        bo.validatableModel @

        bo.bus.publish "commandCreated:#{@name}", @

    properties: ->
        ko.toJS @_definedProperties

bo.messaging = {}

bo.messaging.config =
    query:
        url: "Query/?query.name=$queryName&query.values=$queryValues"

    queryDownload:
        url: "Query/Download?query.name=$queryName&query.values=$queryValues&contentType=$contentType&fileName=$fileName"
    
    command:
        url: "Command"
        batchUrl: "Command/Batch"
        optionsParameterName: 'values'

bo.messaging.query = (queryName, options = {}, ajaxOptions = {}) ->
    bo.arg.ensureDefined queryName, "queryName"
    
    bo.bus.publish "queryExecuting:#{queryName}", { name: queryName, values: options }

    queryDeferred = new jQuery.Deferred()

    request = _.extend {}, ajaxOptions, 
                    url: bo.config.appRoot + bo.messaging.config.query.url.replace("$queryValues", encodeURIComponent ko.toJSON options).replace("$queryName", queryName)
                    type: "GET"
                    dataType: "json"
                    contentType: "application/json; charset=utf-8"
    
    ajaxPromise = jQuery.ajax request

    doResolve = (result, hasFailed) ->
        messageArgs = 
            name: queryName 
            values: options
            result: result
            hasFailed: hasFailed
      
        shouldContinue = bo.bus.publish "queryResultReceived:#{queryName}", messageArgs 

        if shouldContinue and messageArgs.hasFailed is false
            bo.bus.publish "queryExecuted:#{queryName}", messageArgs
            queryDeferred.resolve result
        else
            bo.bus.publish "queryFailed:#{queryName}", messageArgs
            queryDeferred.reject result

    ajaxPromise.done (result) ->
        doResolve result, false

    ajaxPromise.fail (result) ->
        doResolve undefined, true

    queryDeferred.promise()

bo.messaging.queryDownload = (queryName, contentType, fileName, options = {}, ajaxOptions = {}) ->
    bo.arg.ensureDefined queryName, "queryName"
    bo.arg.ensureDefined queryName, "contentType"
    
    bo.bus.publish "queryExecuting:#{queryName}", { name: queryName, values: options }

    url = bo.config.appRoot + bo.messaging.config.queryDownload.url
                                .replace("$queryValues", encodeURIComponent ko.toJSON options)
                                .replace("$queryName", queryName)
                                .replace("$contentType", contentType)
                                .replace("$fileName", fileName)

    form = document.createElement "form"
    document.body.appendChild form
    form.method = "post"
    form.action = url

    c = document.createElement "input"
    c.type = "submit"

    form.appendChild c
    form.submit()

    document.body.removeChild form

bo.messaging.command = (command) ->
    bo.arg.ensureDefined command, "command"

    commandName = command.name
    commandValues = ko.toJS command.properties()

    bo.bus.publish "commandExecuting:#{commandName}", { command: command, values: commandValues }

    commandDeferred = new jQuery.Deferred()

    ajaxPromise = jQuery.ajax
                    url: bo.config.appRoot + bo.messaging.config.command.url.replace("$commandName", commandName)
                    type: "POST"
                    data: ko.toJSON { command: { name: commandName, values: commandValues } }
                    dataType: "json"
                    contentType: "application/json; charset=utf-8"

    doResolve = (result, hasFailed) ->
        messageArgs = 
            command: command
            values: commandValues
            result: result
            hasFailed: hasFailed
      
        shouldContinue = bo.bus.publish "commandResultReceived:#{commandName}", messageArgs 

        if shouldContinue and messageArgs.hasFailed is false
            bo.bus.publish "commandExecuted:#{commandName}", messageArgs
            commandDeferred.resolve result
        else
            bo.bus.publish "commandFailed:#{commandName}", messageArgs
            commandDeferred.reject result

    ajaxPromise.done (result) ->
        doResolve result, false

    ajaxPromise.fail (result) ->
        doResolve undefined, true

    commandDeferred.promise()

bo.messaging.commands = (commands) ->
    bo.arg.ensureDefined commands, "commands"

    commandDeferred = new jQuery.Deferred()
    commandsToSend = ko.utils.arrayMap commands, (c) ->
                        { name: c.name, values: c.properties() }

    ajaxPromise = jQuery.ajax
                    url: bo.config.appRoot + bo.messaging.config.command.batchUrl
                    type: "POST"
                    data: ko.toJSON { commands: commandsToSend }
                    dataType: "json"
                    contentType: "application/json; charset=utf-8"

    doResolve = (result, hasFailed) ->
        messageArgs = 
            commands: commands,
            commandValues: commandsToSend
            result: result
            hasFailed: hasFailed
      
        shouldContinue = bo.bus.publish "commandResultReceived:Batch", messageArgs 

        if shouldContinue and messageArgs.hasFailed is false
            bo.bus.publish "commandExecuted:Batch", messageArgs
            commandDeferred.resolve result
        else
            bo.bus.publish "commandFailed:Batch", messageArgs
            commandDeferred.reject result

    ajaxPromise.done (result) ->
        doResolve result, false

    ajaxPromise.fail (result) ->
        doResolve undefined, true

    commandDeferred.promise()