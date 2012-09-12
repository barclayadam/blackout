#reference "../../js/blackout/@bus.coffee"

describe 'Bus', ->
    describe 'Given a new EventBus', ->
        beforeEach ->
            @bus = new bo.EventBus()

        it 'Allows subscribing to named event', ->
            spy = @spy()

            @bus.subscribe "myEvent", spy
            @bus.publish "myEvent"

            expect(spy).toHaveBeenCalledOnce()

        it 'Allows subscribing to multiple named events', ->
            spy = @spy()

            @bus.subscribe ["myEvent", "myOtherEvent"], spy

            @bus.publish "myEvent"
            expect(spy).toHaveBeenCalledOnce()

            @bus.publish "myOtherEvent"
            expect(spy).toHaveBeenCalledTwice()

        it 'Allows unsubscribing from named event using returned token', ->
            spy = @spy()

            subscription = @bus.subscribe "myEvent", spy
            subscription.unsubscribe()

            @bus.publish "myEvent"

            expect(spy.called).toBe false

        it 'Allows unsubscribing from named event using returned token with multiple subscribers to same event', ->
            spy1 = @spy()
            spy2 = @spy()

            @bus.subscribe "myEvent", spy1
            subscription = @bus.subscribe "myEvent", spy2
            subscription.unsubscribe()

            @bus.publish "myEvent"

            expect(spy1).toHaveBeenCalledOnce() 
            expect(spy2.called).toBe false
            
        it 'Allows multiple subscribers to a named event', ->
            spy1 = @spy()
            spy2 = @spy()

            @bus.subscribe "myEvent", spy1
            @bus.subscribe "myEvent", spy2
            @bus.publish "myEvent"

            expect(spy1).toHaveBeenCalledOnce()        
            expect(spy2).toHaveBeenCalledOnce()
            
        it 'Allows subscriptions to namespaced events', ->
            spy1 = @spy()

            @bus.subscribe "myEvent:subNamespace", spy1
            @bus.publish "myEvent:subNamespace"

            expect(spy1).toHaveBeenCalledOnce() 
            
        it 'Should publish a namespaced message to any root subscribers', ->
            spy1 = @spy()

            @bus.subscribe "myEvent", spy1
            @bus.publish "myEvent:subNamespace"

            expect(spy1).toHaveBeenCalledOnce() 
            
        it 'Should publish a namespaced message to any root subscribers with nested namespaces', ->
            spy1 = @spy()

            @bus.subscribe "myEvent", spy1
            @bus.publish "myEvent:subNamespace:anotherSubNamespace"

            expect(spy1).toHaveBeenCalledOnce() 
            
        it 'Should publish a namespaced message to any parent subscribers with nested namespaces', ->
            spy1 = @spy()

            @bus.subscribe "myEvent:subNamespace", spy1
            @bus.publish "myEvent:subNamespace:anotherSubNamespace"

            expect(spy1).toHaveBeenCalledOnce() 
            
        it 'Publishes only to subscribers with same event name', ->
            spy1 = @spy()
            spy2 = @spy()

            @bus.subscribe "myEvent", spy1
            @bus.subscribe "myOtherEvent", spy2
            @bus.publish "myEvent"

            expect(spy1).toHaveBeenCalledOnce() 
            expect(spy2.called).toBe false

        it 'Calls subscribers with single argument passed to publish', ->
            spy = @spy()

            @bus.subscribe "myEvent", spy
            @bus.publish "myEvent", "My Data"

            expect(spy).toHaveBeenCalledWith "My Data"

        it 'Calls subscribers with single complex argument passed to publish', ->
            spy = @spy()

            @bus.subscribe "myEvent", spy
            @bus.publish "myEvent", 
                key: "My Data"

            expect(spy).toHaveBeenCalledWith 
                key: "My Data"