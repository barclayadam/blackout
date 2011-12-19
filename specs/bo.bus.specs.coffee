#reference "../../js/blackout/bo.bus.coffee"

describe 'Bus', ->
    it 'Allows subscribing to named event', ->
        spy = @spy()

        bo.bus.subscribe "myEvent", spy
        bo.bus.publish "myEvent"

        expect(spy).toHaveBeenCalledOnce()

    it 'Allows unsubscribing from named event using returned token', ->
        spy = @spy()

        subscription = bo.bus.subscribe "myEvent", spy
        subscription.unsubscribe()

        bo.bus.publish "myEvent"

        expect(spy.called).toBe false

    it 'Returns true when no subscribers return a value', ->
        stub = @stub()

        bo.bus.subscribe "myEvent", stub
        success = bo.bus.publish "myEvent"

        expect(success).toBe true

    it 'Returns false when subscriber returns false', ->
        stub = @stub().returns false

        bo.bus.subscribe "myEvent", stub
        success = bo.bus.publish "myEvent"

        expect(success).toBe false

    it 'Stops executing subscribers if false returned by earlier subscriber', ->
        falseyStub = @stub().returns false
        secondSubscriptionSpy = @stub().returns true

        bo.bus.subscribe "myEvent", falseyStub
        bo.bus.subscribe "myEvent", secondSubscriptionSpy
        success = bo.bus.publish "myEvent"

        expect(success).toBe false
        expect(falseyStub).toHaveBeenCalledOnce() 
        expect(secondSubscriptionSpy.called).toBe false

    it 'Allows unsubscribing from named event using returned token with multiple subscribers to same event', ->
        spy1 = @spy()
        spy2 = @spy()

        bo.bus.subscribe "myEvent", spy1
        subscription = bo.bus.subscribe "myEvent", spy2
        subscription.unsubscribe()

        bo.bus.publish "myEvent"

        expect(spy1).toHaveBeenCalledOnce() 
        expect(spy2.called).toBe false
        
    it 'Allows multiple subscribers to a named event', ->
        spy1 = @spy()
        spy2 = @spy()

        bo.bus.subscribe "myEvent", spy1
        bo.bus.subscribe "myEvent", spy2
        bo.bus.publish "myEvent"

        expect(spy1).toHaveBeenCalledOnce()        
        expect(spy2).toHaveBeenCalledOnce()
        
    it 'Allows subscriptions to namespaced events', ->
        spy1 = @spy()

        bo.bus.subscribe "myEvent:subNamespace", spy1
        bo.bus.publish "myEvent:subNamespace"

        expect(spy1).toHaveBeenCalledOnce() 
        
    it 'Should publish a namespaced message to any root subscribers', ->
        spy1 = @spy()

        bo.bus.subscribe "myEvent", spy1
        bo.bus.publish "myEvent:subNamespace"

        expect(spy1).toHaveBeenCalledOnce() 
        
    it 'Should publish a namespaced message to any root subscribers with nested namespaces', ->
        spy1 = @spy()

        bo.bus.subscribe "myEvent", spy1
        bo.bus.publish "myEvent:subNamespace:anotherSubNamespace"

        expect(spy1).toHaveBeenCalledOnce() 
        
    it 'Should publish a namespaced message to any parent subscribers with nested namespaces', ->
        spy1 = @spy()

        bo.bus.subscribe "myEvent:subNamespace", spy1
        bo.bus.publish "myEvent:subNamespace:anotherSubNamespace"

        expect(spy1).toHaveBeenCalledOnce() 
        
    it 'Publishes only to subscribers with same event name', ->
        spy1 = @spy()
        spy2 = @spy()

        bo.bus.subscribe "myEvent", spy1
        bo.bus.subscribe "myOtherEvent", spy2
        bo.bus.publish "myEvent"

        expect(spy1).toHaveBeenCalledOnce() 
        expect(spy2.called).toBe false

    it 'Calls subscribers with single argument passed to publish', ->
        spy = @spy()

        bo.bus.subscribe "myEvent", spy
        bo.bus.publish "myEvent", "My Data"

        expect(spy).toHaveBeenCalledWith "My Data"
        
    it 'Calls subscribers with multiple arguments passed to publish', ->
        spy = @spy()

        bo.bus.subscribe "myEvent", spy
        bo.bus.publish "myEvent", "My Data", "My Other Data"

        expect(spy).toHaveBeenCalledWith "My Data", "My Other Data"
