#reference "bo.coffee"

# Will be:
#   subscribers
#       eventName:
#           tokenId: func1
#           tokenId1: func2
#       ...
class bo.Bus
    constructor: (@busOptions) ->
        @_initBus()

    _initBus: ->
        @busOptions = { global: false, log: true } if not @busOptions?

        @_subscribers = {}
        @_currentToken = 0

        @_initBus = ->

    clearAll: ->
        @_subscribers = {}

    # Subscribes the given function to the specified messageName, being executed
    # if the exact same named event is raised.
    #
    # The return result from this function is a subscription, an object that
    # has a single 'unsubscribe' method that, if called, will dispose of the
    # subscription to the named event meaning no further events will be published
    # to the give function.
    subscribe: (messageName, func) ->
        bo.arg.ensureString messageName, 'messageName'
        bo.arg.ensureFunction func, 'func'

        @_initBus()

        @_subscribers[messageName] = {} if @_subscribers[messageName] is undefined

        @_currentToken = ++@_currentToken
        tokenToUse = @_currentToken

        @_subscribers[messageName][tokenToUse] = func

        {
            unsubscribe: =>
                delete @_subscribers[messageName][tokenToUse]
        }

    # Publishes the given named message to any subscribed listeners, passing 
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
    publish: (messageName, args...) ->
        bo.arg.ensureString messageName, 'messageName'

        @_initBus()

        if @busOptions.log is true
            if @busOptions.global is false
                console.log "Publishing #{messageName} (local)" 
            else
                console.log "Publishing #{messageName}"

        if @busOptions.global is false
            bo.bus.publish messageName, args

        indexOfSeparator = -1
        messages = [messageName]

        messages.push messageName while messageName = messageName.substring 0, (messageName.lastIndexOf ':')

        for msg in messages
            for t, subscriber of (@_subscribers[msg] || {})
                canContinue = subscriber.apply @, args

                if canContinue is false
                    return false
            
        true

bo.bus = new bo.Bus { global: true, log: true }