EventBus = ->
    _subscribers = {}
    
    clearAll = ->
        _subscribers = {}
 
    # Subscribes the given function to the specified messageName, being executed
    # if the exact same named event is raised or a `namespaced` event published
    # with a root of the given `messageName` (e.g. publishing a message with
    # the name `myNamespace:myEvent` will call subscribers of both 
    # `myNamespace:myEvent` and `myNamespace`).
    #
    # The return result from this function is a subscription, an object that
    # has a single 'unsubscribe' method that, if called, will dispose of the
    # subscription to the named event meaning no further events will be published
    # to the given function.
    subscribe = (messageName, callback) ->
        if _.isArray messageName
            for message in messageName
                subscribe message, callback

            undefined
        else
            if _subscribers[messageName] is undefined
                _subscribers[messageName] = {} 

            newToken = _.size _subscribers[messageName]

            _subscribers[messageName][newToken] = callback

            # Return value for a subscription which is an object with
            # a single `unsubscribe` method which will dispose of subscription
            # on execution to stop any further publications from executing
            # the specified `callback`.
            unsubscribe: ->
                delete _subscribers[messageName][newToken]

    # Publishes the given named message to any subscribed listeners, passing 
    # the `messageData` argument on to each subscriber as an arguments to the 
    # subscription call.
    #
    # (e.g. 
    #    subscribe "My Event", (messageData) ->
    #    publish   "My Event", messageData
    # )
    publish = (messageName, args = {}) ->
        bo.log.debug "Publishing #{messageName}", args

        indexOfSeparator = -1
        messages = [messageName]

        while messageName = messageName.substring 0, messageName.lastIndexOf ':'
            messages.push messageName 

        for msg in messages
            for t, subscriber of (_subscribers[msg] || {})
                subscriber.call @, args

        undefined

    return {
        clearAll: clearAll
        subscribe: subscribe
        publish: publish
    }

bo.EventBus = EventBus
bo.bus = new bo.EventBus