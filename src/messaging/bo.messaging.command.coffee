messaging = bo.messaging ?= {}

messaging.commandUrlTemplate = 'Command/{name}'

# Executes a 'command', something that is simply defined as an AJAX call to a predefined
# URL that has the name injected and JSON values POSTed.
#
# The URL template that is used is defined by `bo.messaging.commandUrlTemplate`, with two
# placeholders that will be replaced:
#
# * `{name}`: Replaced by the value of `queryName` passed to this method
#
# This method returns a promise that will resolve with the value of the AJAX call.
messaging.command = (commandName, values = {}) ->
    bo.log.info "Executing command '#{commandName}'."

    bo.ajax.url(messaging.commandUrlTemplate.replace("{name}", commandName))
        .data(values)
        .post()

# TODO: This should not differ just on capitilisation of the C!

class messaging.Command
    # Initialises a new instance of the `bo.messaging.Command` class with the
    # specified name and default values. 
    #
    # The `defaultValues` object defines all properties of a command, no properties 
    # defined on a command that are not included in this object will be serialised 
    # when the command is executed.
    constructor: (name, @defaultValues) ->
        @__name = name

        for key, value of defaultValues
            @[key] = bo.utils.asObservable value

        bo.validation.mixin @

    execute: () ->
        @validate()

        if @isValid()
            messaging.command @__name, @
        else
            # If not valid then a promise that never resolves is returned.
            # TODO: Is this the correct thing to do?
            jQuery.Deferred()

    toJSON: () ->
        definedValues = {}

        for key, value of @defaultValues
            definedValues[key] = ko.utils.unwrapObservable @[key]

        definedValues