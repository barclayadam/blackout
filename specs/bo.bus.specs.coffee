#reference "../../js/blackout/@bus.coffee"

describe 'Bus', ->
    describe 'Given a new Bus', ->
        beforeEach ->
            @bus = new bo.Bus()

        it 'Allows subscribing to named event', ->
            spy = @spy()

            @bus.subscribe "myEvent", spy
            @bus.publish "myEvent"

            expect(spy).toHaveBeenCalledOnce()

        it 'Allows unsubscribing from named event using returned token', ->
            spy = @spy()

            subscription = @bus.subscribe "myEvent", spy
            subscription.unsubscribe()

            @bus.publish "myEvent"

            expect(spy.called).toBe false

        it 'Returns true when no subscribers return a value', ->
            stub = @stub()

            @bus.subscribe "myEvent", stub
            success = @bus.publish "myEvent"

            expect(success).toBe true

        it 'Returns false when subscriber returns false', ->
            stub = @stub().returns false

            @bus.subscribe "myEvent", stub
            success = @bus.publish "myEvent"

            expect(success).toBe false

        it 'Stops executing subscribers if false returned by earlier subscriber', ->
            falseyStub = @stub().returns false
            secondSubscriptionSpy = @stub().returns true

            @bus.subscribe "myEvent", falseyStub
            @bus.subscribe "myEvent", secondSubscriptionSpy
            success = @bus.publish "myEvent"

            expect(success).toBe false
            expect(falseyStub).toHaveBeenCalledOnce() 
            expect(secondSubscriptionSpy.called).toBe false

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
            
        it 'Calls subscribers with multiple arguments passed to publish', ->
            spy = @spy()

            @bus.subscribe "myEvent", spy
            @bus.publish "myEvent", "My Data", "My Other Data"

            expect(spy).toHaveBeenCalledWith "My Data", "My Other Data"

    describe 'Given a class inheriting from Bus', ->
        class MyViewModel extends bo.Bus
            doPublish: ->
                @publish 'myEvent'

        beforeEach ->
            @viewModel = new MyViewModel()

        it 'should publish to local listeners', ->
            # Arrange
            spy = @spy()
            @viewModel.subscribe 'myEvent', spy

            # Act
            @viewModel.doPublish()

            # Arrange
            expect(spy).toHaveBeenCalled()

        it 'should publish to the global bus', ->
            # Act
            @viewModel.doPublish()

            # Arrange
            expect('myEvent').toHaveBeenPublished() # To 'global' bus
