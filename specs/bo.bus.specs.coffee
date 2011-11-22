#reference "../../js/blackout/bo.bus.coffee"

describe 'Bus', ->
    it 'Allows subscribing to named event', ->
        spy = @spy()

        bo.bus.subscribe "MyEvent", spy
        bo.bus.publish "MyEvent"

        expect(spy).toHaveBeenCalledOnce()

    it 'Allows unsubscribing from named event using returned token', ->
        spy = @spy()

        token = bo.bus.subscribe "MyEvent", spy
        bo.bus.unsubscribe token

        bo.bus.publish "MyEvent"

        expect(spy.called).toBe false

    it 'Returns true when no subscribers return a value', ->
        stub = @stub()

        token = bo.bus.subscribe "MyEvent", stub
        success = bo.bus.publish "MyEvent"

        expect(success).toBe true

    it 'Returns false when subscriber returns false', ->
        stub = @stub().returns false

        token = bo.bus.subscribe "MyEvent", stub
        success = bo.bus.publish "MyEvent"

        expect(success).toBe false

    it 'Stops executing subscribers if false returned by earlier subscriber', ->
        falseyStub = @stub().returns false
        truthyStub = @stub().returns true

        token = bo.bus.subscribe "MyEvent", falseyStub
        token = bo.bus.subscribe "MyEvent", truthyStub
        success = bo.bus.publish "MyEvent"

        expect(success).toBe false
        expect(falseyStub).toHaveBeenCalledOnce() 
        expect(truthyStub.called).toBe false

    it 'Allows unsubscribing from named event using returned token with multiple subscribers to same event', ->
        spy1 = @spy()
        spy2 = @spy()

        bo.bus.subscribe "MyEvent", spy1
        token = bo.bus.subscribe "MyEvent", spy2
        bo.bus.unsubscribe token

        bo.bus.publish "MyEvent"

        expect(spy1).toHaveBeenCalledOnce() 
        expect(spy2.called).toBe false
        
    it 'Allows multiple subscribers to a named event', ->
        spy1 = @spy()
        spy2 = @spy()

        bo.bus.subscribe "MyEvent", spy1
        bo.bus.subscribe "MyEvent", spy2
        bo.bus.publish "MyEvent"

        expect(spy1).toHaveBeenCalledOnce()        
        expect(spy2).toHaveBeenCalledOnce()
        
    it 'Publishes only to subscribers with same event name', ->
        spy1 = @spy()
        spy2 = @spy()

        bo.bus.subscribe "MyEvent", spy1
        bo.bus.subscribe "MyOtherEvent", spy2
        bo.bus.publish "MyEvent"

        expect(spy1).toHaveBeenCalledOnce() 
        expect(spy2.called).toBe false

    it 'Calls subscribers with single argument passed to publish', ->
        spy = @spy()

        bo.bus.subscribe "MyEvent", spy
        bo.bus.publish "MyEvent", "My Data"

        expect(spy).toHaveBeenCalledWith "My Data"
        
    it 'Calls subscribers with multiple arguments passed to publish', ->
        spy = @spy()

        bo.bus.subscribe "MyEvent", spy
        bo.bus.publish "MyEvent", "My Data", "My Other Data"

        expect(spy).toHaveBeenCalledWith "My Data", "My Other Data"
