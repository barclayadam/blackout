describe 'UIAction', ->
    describe 'basic action with no configuration', ->
        beforeEach ->
            @actionSpy = @spy =>
                @executingDuringProcessing = @action.executing()
                "My Return Value"

            @action = bo.UiAction @actionSpy

            @returnValue = @action.execute 'A Value'

        it 'should have an execute function', ->
            expect(@action.execute).toBeAFunction()

        it 'should pass through calls to the configured function', ->
            expect(@actionSpy).toHaveBeenCalled()

        it 'should pass through arguments to the configured function', ->
            expect(@actionSpy).toHaveBeenCalledWith 'A Value'

        it 'should return value of action', ->
            expect(@returnValue).toEqual "My Return Value"

        it 'should have an always-true enabled observable attached', ->
            expect(@action.enabled).toBeObservable()
            expect(@action.enabled()).toBe true

        it 'should have executing observable that is true only when executing', ->            
            expect(@executingDuringProcessing).toBe true
            expect(@action.executing()).toBe false # Now execution has finished

    describe 'basic action with enabled observable passed', ->
        beforeEach ->
            @actionSpy = @spy =>
                @executingDuringProcessing = @action.executing()
            
            @enabled = ko.observable true

            @action = bo.UiAction 
                enabled: @enabled
                action: @actionSpy

        describe 'when enabled is true', ->
            beforeEach ->
                @enabled true
                @action.execute 'A Value'

            it 'should pass through calls to the configured function', ->
                expect(@actionSpy).toHaveBeenCalled()

            it 'should pass through arguments to the configured function', ->
                expect(@actionSpy).toHaveBeenCalledWith 'A Value'

            it 'should have a true enabled observable attached', ->
                expect(@action.enabled()).toBe true

            it 'should have executing observable that is true only when executing', ->            
                expect(@executingDuringProcessing).toBe true
                expect(@action.executing()).toBe false # Now execution has finished

        describe 'when enabled is false', ->
            beforeEach ->
                @enabled false
                @action.execute 'A Value'

            it 'should not pass through calls to the configured function', ->
                expect(@actionSpy).toHaveNotBeenCalled()

            it 'should have a false enabled observable attached', ->
                expect(@action.enabled()).toBe false

    describe 'async action that returns promise', ->
        beforeEach ->
            @deferred = jQuery.Deferred()

            @actionSpy = @spy =>
                @executingDuringProcessing = @action.executing()
                @deferred
            
            @action = bo.UiAction @actionSpy
            @action.execute()

        it 'should have executing observable that is true whilst deferred has not resolved', ->            
            expect(@executingDuringProcessing).toBe true
            expect(@action.executing()).toBe true # Execution has not finished yet

        it 'should have executing observable that is false when deferred resolves', -> 
            @deferred.resolve()

            expect(@action.executing()).toBe false # Execution has finished 

    describe 'async action that returns promise, marked as serial', ->
        beforeEach ->
            @deferred = jQuery.Deferred()

            @actionSpy = @spy =>
                @deferred
            
            @action = bo.UiAction 
                serial: true

                action: @actionSpy

            @action.execute()
            @action.execute()
            @action.execute()

        it 'should only execute function once whilst the first has not completed', ->            
            expect(@actionSpy).toHaveBeenCalledOnce()