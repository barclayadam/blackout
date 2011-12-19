# reference "../lib/jquery.js"
# reference "../lib/jquery.ui.js"
# reference "../lib/knockout.js"
# reference "bo.coffee"

ko.bindingHandlers.hoverClass =
    init: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()
        $element = jQuery(element)
        $element.hover (-> $element.addClass value), (-> $element.removeClass value)
        
ko.bindingHandlers.flash =
    update: (element, valueAccessor) ->
        $element = jQuery(element)
        value = ko.utils.unwrapObservable valueAccessor()

        if value?
            $element.html(value).hide().slideDown(350)
            setTimeout (-> $element.fadeOut()), 3500
        else
            $element.hide()

ko.bindingHandlers.yesno =
    update: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()

        element.innerHTML = (if value then "Yes" else "No")

ko.bindingHandlers.fadeVisible =
    init: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()

        if value then $(element).show() else $(element).hide()

    update: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()

        if value then $(element).fadeIn() else $(element).fadeOut()

ko.bindingHandlers.position =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        $element = jQuery element
        value = ko.utils.unwrapObservable valueAccessor()

        options = 
            my: value.my || 'left top'
            at: value.at || 'right'
            of: value.of
            offset: value.offset || '0 0'
            collision: value.collision || 'fit'

        if $element.width() is 0
            $element.width ko.utils.unwrapObservable value.width

        $element.position options

originalEnableBindingHandler = ko.bindingHandlers.enable

ko.bindingHandlers.enable =
    init: (element, valueAccessor, allBindings, viewModel) ->
        originalEnableBindingHandler.init element, valueAccessor, allBindings, viewModel if originalEnableBindingHandler.init?
        
    update: (element, valueAccessor, allBindings, viewModel) ->
        originalEnableBindingHandler.update element, valueAccessor, allBindings, viewModel if originalEnableBindingHandler.update?

        isEnabled = ko.utils.unwrapObservable valueAccessor()
        $element = jQuery element

        $element.toggleClass "ui-state-disabled", !isEnabled

ko.bindingHandlers.command =
    shouldExecute: (enableOption, viewModel) ->
        enable = ko.utils.unwrapObservable enableOption

        if enable?
            if _.isFunction enable then (enable.apply viewModel) else enable
        else
            true

    init: (element, valueAccessor, allBindings, viewModel) ->
        commands = valueAccessor() || {}

        if not _.isArray commands
            commands = [commands]

        ko.utils.arrayForEach commands, (options, i) ->        
            callback = if _.isFunction options then options else options.callback

            if callback
                enable = options.enable || allBindings().enable
                eventName = options.event
                keyboardShortcut = options.keyboard

                doExecute = ->
                    if ko.bindingHandlers.command.shouldExecute enable, viewModel
                        callback.apply(viewModel) || false
                    else
                        true
        
                if eventName
                    newValueAccessor = ->
                        result = {}
                        result[eventName] = doExecute
                        result

                    ko.bindingHandlers.event.init.call @, element, newValueAccessor, allBindings, viewModel

                if keyboardShortcut
                    jQuery(element).bind 'keydown', keyboardShortcut, (event) ->                    
                        doExecute()

                        event.stopPropagation()
                        event.preventDefault()
                        false

currentValueBinding = ko.bindingHandlers.value

ko.bindingHandlers.value =
    init: ->
        currentValueBinding.init.apply @, arguments
        ko.bindingHandlers.validated.init.apply @, arguments

    update: ->
        currentValueBinding.update.apply @, arguments
        ko.bindingHandlers.validated.update.apply @, arguments
                        
ko.bindingHandlers.validated =
    options:
        inputValidClass: 'input-validation-valid'
        inputInvalidClass: 'input-validation-error'

        messageValidClass: 'field-validation-valid'
        messageInvalidClass: 'field-validation-error'

    init: (element, valueAccessor, allBindings, viewModel) ->
        value = valueAccessor()
        $element = jQuery element

        if value?.errors?
            $validationElement = jQuery('<span />').insertAfter $element
            ko.utils.domData.set element, 'validationElement', $validationElement

        if value?.validationRules?.required?
            $element.attr "aria-required", true

    update: (element, valueAccessor, allBindings, viewModel) ->
        $element = jQuery element
        $validationElement = ko.utils.domData.get element, 'validationElement'
        value = valueAccessor()
        
        if value?.errors?        
            shouldEnable = ko.utils.unwrapObservable(allBindings().enable || true)
            shouldDisable = ko.utils.unwrapObservable(allBindings().disable || false)

            isEnabled = shouldEnable is true and shouldDisable is false
        
            errorMessages = value.errors()
            options = ko.bindingHandlers.validated.options

            isInvalid = isEnabled and errorMessages.length > 0
            isValid = not isInvalid

            $element.toggleClass options.inputValidClass, isValid
            $element.toggleClass options.inputInvalidClass, isInvalid

            $element.attr "aria-invalid", isInvalid
            
            $validationElement.toggleClass options.messageValidClass, isValid
            $validationElement.toggleClass options.messageInvalidClass, isInvalid

            $validationElement.html (if isValid then '' else errorMessages.join '<br />')

# Binding to do event delegation for any event
# Converted JavaScript from: http://www.knockmeout.net/2011/04/event-delegation-in-knockoutjs.html
ko.bindingHandlers.delegatedEvent =
    init: (element, valueAccessor, allBindings, viewModel) ->
        eventsToHandle = valueAccessor() or {}
        eventsToHandle = [ eventsToHandle ] unless _.isArray(eventsToHandle)

        ko.utils.arrayForEach eventsToHandle, (eventOptions) ->
            realCallback = (event) ->
                element = event.target
                options = eventOptions

                if jQuery(element).is(options.selector)
                    context = $(event.target).tmplItem().data

                    if typeof options.callback == "string" and typeof context[options.callback] == "function"
                        [options.callback].call(context, event)
                    else
                        options.callback.call viewModel, context, event

                    false

                true
    
            realValueAccessor = ->
                result = {}
                result[eventOptions.event] = realCallback
                result
                
            ko.bindingHandlers.event.init element, realValueAccessor, allBindings, viewModel
