#reference "../lib/jquery.js"
#reference "../lib/knockout.js"
#reference "bo.coffee"
#reference "bo.utils.coffee"
#reference "bo.routing.coffee"
#reference "bo.bus.coffee"

class bo.ViewModel
    constructor: ->
        @_toValidate = ko.observableArray()

        @isDirty = ko.observable false

        if @getCommandsToSubmit? 
            @commandsToSubmit = ko.computed 
                read: @getCommandsToSubmit.bind @
                deferEvaluation: true
        else
            @commandsToSubmit = ko.observable []

        @canSubmit = ko.computed 
            read: => @isDirty() and @commandsToSubmit().length > 0        
            deferEvaluation: true
        
    reset: ->
        @isDirty false

    set: (propertyName, value) ->
        if @[propertyName]
            @[propertyName] value
        else
            newObs = bo.utils.asObservable value

            @[propertyName] = newObs
            @_toValidate.push newObs
            @registerForDirtyTracking newObs

        @[propertyName]

    setAll: (properties) ->
        @set propertyName, value for propertyName, value of properties

    registerForDirtyTracking: (o) ->
        if o?.subscribe?
            o.subscribe (newValue) =>
                @isDirty true

        propValue = ko.utils.unwrapObservable o

        if (jQuery.type propValue) is 'object'
            @registerForDirtyTracking value for key, value of propValue

    validate: ->
        for obj in @_toValidate() 
            unwrapped = (ko.utils.unwrapObservable obj)
            unwrapped.validate() if unwrapped?.validate?

        @_areCommandsToSubmitValid()

    submit: ->
        @validate()

        if @_areCommandsToSubmitValid() and @canSubmit()
            if @commandsToSubmit().length is 1
                ajaxPromise = bo.messaging.command @commandsToSubmit()[0]
            else
                ajaxPromise = bo.messaging.commands @commandsToSubmit()

            ajaxPromise.done =>
                @reset()
                @onSubmitSuccess() if @onSubmitSuccess?

            ajaxPromise
        else
            bo.utils.failedPromise()

    _areCommandsToSubmitValid: ->
        _.all @commandsToSubmit(), (c) -> c.isValid()

bo.ViewModel.subclass = (constructorFunc) ->
    class viewModel extends bo.ViewModel
        constructor: ->
            super()
            constructorFunc.apply @, arguments if constructorFunc
            
    viewModel