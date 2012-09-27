# reference "../lib/jquery.js"
# reference "../lib/jquery.ui.js"
# reference "../lib/knockout.js"
# reference "bo.coffee"

ko.bindingHandlers.hoverClass =
    init: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()
        $element = jQuery(element)
        $element.hover (-> $element.addClass value), (-> $element.removeClass value)
        
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

originalTextUpdate = ko.bindingHandlers.text.update

ko.bindingHandlers.text.update = (element, viewModelAccessor, allBindingsAccessor) ->
    valueAccessor = ->
        ko.utils.unwrapObservable(viewModelAccessor()) || allBindingsAccessor().defaultValue

    originalTextUpdate element, valueAccessor, allBindingsAccessor