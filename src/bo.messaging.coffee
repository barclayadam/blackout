#reference "bo.coffee"
#reference "bo.utils.coffee"

class bo.Command  
    constructor: (@name, values = {}) ->
        bo.validatableModel @

        for key, value of values
            @[key] = bo.utils.asObservable value

    properties: ->
        properties = {}
        properties[key] = value for key, value of @ when not _(['name', 'validate', 'modelErrors', 'properties', 'modelValidationRules', 'isValid']).contains key
        properties

bo.messaging = {}

# A function that can be overriden by an application to process any options
# before they are sent to the server.
bo.messaging.processOptions = (options) -> options

bo.messaging.config =
    query:
        url: "/Query/?query.name=$queryName&query.values=$queryValues"

    queryDownload:
        url: "/Query/Download?query.name=$queryName&query.values=$queryValues&contentType=$contentType"
    
    command:
        url: "/Command"
        batchUrl: "/Command/Batch"
        optionsParameterName: 'values'

bo.messaging.query = (queryName, options = {}) ->
    bo.arg.ensureDefined queryName, "queryName"
    
    queryOptions = bo.messaging.processOptions options
    
    jQuery.ajax
        url: bo.messaging.config.query.url.replace("$queryValues", ko.toJSON queryOptions).replace("$queryName", queryName)
        type: "GET"
        dataType: "json"
        contentType: "application/json; charset=utf-8"

bo.messaging.queryDownload = (queryName, contentType, options = {}) ->
    bo.arg.ensureDefined queryName, "queryName"
    bo.arg.ensureDefined queryName, "contentType"
    
    queryOptions = bo.messaging.processOptions options
    url = bo.messaging.config.queryDownload.url.replace("$queryValues", ko.toJSON queryOptions).replace("$queryName", queryName).replace("$contentType", contentType)

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
    commandProperties = command.properties()
   
    commandProperties = bo.messaging.processOptions commandProperties

    jQuery.ajax
        url: bo.messaging.config.command.url.replace("$commandName", commandName)
        type: "POST"
        data: ko.toJSON { command: { name: commandName, values: commandProperties } }
        dataType: "json"
        contentType: "application/json; charset=utf-8"

bo.messaging.commands = (commands) ->
    bo.arg.ensureDefined commands, "commands"

    jQuery.ajax
        url: bo.messaging.config.command.batchUrl
        type: "POST"
        data: ko.toJSON
            commands: (ko.utils.arrayMap commands, (c) ->
                { name: c.name, values: c.properties() })
        dataType: "json"
        contentType: "application/json; charset=utf-8"