#reference "bo.coffee"

# Will be:
#   subscribers
#       eventName:
#           tokenId: func1
#           tokenId1: func2
#       ...
subscribers = {}
token = 0

bo.bus = 
    clearAll: ->
        subscribers = {}

    # Subscribes the given function to the specified eventName, being executed
    # if the exact same named event is raised.
    #
    # The return result from this function is a subscription, an object that
    # has a single 'unsubscribe' method that, if called, will dispose of the
    # subscription to the named event meaning no further events will be published
    # to the give function.
    subscribe: (eventName, func) ->
        bo.arg.ensureString eventName, 'eventName'
        bo.arg.ensureFunction func, 'func'

        subscribers[eventName] = {} if subscribers[eventName] is undefined

        token = ++token
        subscribers[eventName][token] = func

        {
            unsubscribe: ->
                delete subscribers[eventName][token]
        }

    # Publishes the given named event to any subscribed listeners, passing 
    # any arguments on to each subscriber as arguments to the subscription call
    #
    # (e.g. 
    #    subscribe "My Event", (x, y) ->
    #    publish   "My Event", x, y
    # )
    #
    # If any subscriber returns `false` then no further subscribers will be
    # notified of the event and `false` will be returned from this method, indicating
    # a failure.
    publish: (eventName, args...) ->
        bo.arg.ensureString eventName, 'eventName'

        indexOfSeparator = -1
        events = [eventName]

        events.push eventName while eventName = eventName.substring 0, (eventName.lastIndexOf ':')

        for e in events
            for t, subscriber of (subscribers[e] || {})
                canContinue = subscriber.apply @, args

                if canContinue is false
                    return false
            
        true
