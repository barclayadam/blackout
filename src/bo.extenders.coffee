# reference "../lib/jquery.js"
# reference "../lib/jquery.hotkeys.js"
# reference "../lib/knockout.js"

# reference "bo.coffee"
# reference "bo.query.coffee"

# An extender that will make an observable 'publishable', in that on
# write an event will be published with the new value.
#
# If any subscribers wishes to revert the change they can return false,
# in which case this observable will be set back to its original value
# and raise another set of subscription events.
ko.extenders.publishable = (target, messageOrOptions) ->
    messageNameOrFunction = messageOrOptions
    bus = bo.bus

    if not _.isString messageOrOptions
        messageNameOrFunction = messageOrOptions.message
        bus = messageOrOptions.bus

    result = ko.computed
        read: target

        write: (value) ->
            currentValue = target()
            target value

            messageName = messageNameOrFunction

            if _.isFunction messageNameOrFunction
                messageName = messageNameOrFunction result

            shouldChange = bus.publish messageName, value

            if shouldChange is false
                target currentValue
                
    result

# An extender that will make an observable 'on demand'
ko.extenders.onDemand = (target, loader) ->
    target.subscribe ->
        target.loaded true
        target.isLoading false
  
    target.isLoading = ko.observable false
    target.loaded = ko.observable false

    target.load = (loadedCallback) ->
        if (!target.loaded()) 
            target.isLoading true

            if (loadedCallback?)
                subscription = target.loaded.subscribe ->
                    loadedCallback()
                    subscription.dispose()
           
            loader target
        else
            loadedCallback() if loadedCallback?

    target.refresh = ->
        target.loaded false
        target.load()     

    target

ko.extenders.async = (target, loaderOrOptions) ->
    if _.isFunction loaderOrOptions
        options = 
            callback: loaderOrOptions
            throttle: 250
    else 
        options = loaderOrOptions

    target.subscribe ->
        target.isLoading false
  
    target.isLoading = ko.observable false

    asyncLoader = ko.computed(->
        target.isLoading true
        options.callback target
    )
    
    if options.throttle > 0
        asyncLoader.extend
             throttle: options.throttle

    target