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
    # The return result from this function is a 'token', a piece of data
    # that can be passed to the bo.bus.unsubscribe function to stop receiving
    # events from the bus.
    subscribe: (eventName, func) ->
        bo.arg.ensureString eventName, 'eventName'
        bo.arg.ensureFunction func, 'func'

        subscribers[eventName] = {} if subscribers[eventName] is undefined

        token = ++token
        subscribers[eventName][token] = func

        [eventName, token]

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

        for t, subscriber of (subscribers[eventName] || {})
            canContinue = subscriber.apply @, args

            if canContinue is false
                return false
            
        true             

    # Removes the subscription represented by the specified token, which is
    # the value returned when registering a subscriber using the bo.bus.subscribe
    # method.
    unsubscribe: (token) ->
        # token[0] == eventName
        # token[1] == token (an integer)
        bo.arg.ensureDefined token, 'token'

        subscriptionList = subscribers[token[0]]
        delete subscriptionList[token[1]]