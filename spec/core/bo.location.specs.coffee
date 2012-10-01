testHistoryPolyfill = false

describe 'location', ->
    beforeEach ->
        @currentLocation = window.location.pathname
        @currentTitle = document.title

    afterEach ->
        window.history.replaceState {}, @currentTitle, @currentLocation

    if testHistoryPolyfill
        describe 'polyfill', ->

            describe 'pushState and replaceState polyfill', ->
                it 'should have history.pushState available', ->
                    expect(window.history.pushState).toBeAFunction()

                it 'should have history.replaceState available', ->
                    expect(window.history.replaceState).toBeAFunction()

                describe 'pushState', ->
                    beforeEach ->               
                        window.history.pushState {}, 'New Title', 'MyNewUrl'

                    # Note this makes the ignored second parameter of title useful
                    it 'should set document.title to supplied title', ->
                       expect(document.title).toEqual 'New Title'

                    it 'should change URL (in some way) to include the new URL', ->
                        expect(window.location.toString()).toContain 'MyNewUrl'

                    it 'should return the new URL from routePath, with a preceeding slash', ->
                        # Contains so we do not take into account path root.
                        # routePath to use browser normalisation
                        expect(bo.location.routePath()).toContain '/MyNewUrl'

                    describe 'when going back', ->
                        beforeEach ->
                            runs ->
                                @popstateSpy = @spy()
                                ko.utils.registerEventHandler window, "popstate", @popstateSpy
                                
                                window.history.go -1

                            waits 400

                        it 'should raise a popstate event', ->
                            expect(@popstateSpy).toHaveBeenCalledOnce()

                        it 'should return to URL as was at time of pushState', ->
                            expect(window.location.pathname).toEqual @currentLocation

                describe 'replaceState', ->
                    beforeEach ->
                        window.history.replaceState {}, 'New Title', 'MyNewUrl'

                    # Note this makes the ignored second parameter of title useful
                    it 'should set document.title to supplied title', ->
                       expect(document.title).toEqual 'New Title'

                    it 'should change URL (in some way) to include the new URL', ->
                        expect(window.location.toString()).toContain 'MyNewUrl'

                    it 'should return the new URL from routePath, with a preceeding slash', ->
                        # Contains so we do not take into account path root
                        # routePath to use browser normalisation
                        expect(bo.location.routePath()).toContain '/MyNewUrl'

                    describe 'when going back', ->
                        beforeEach ->
                            # Push another state, meaning the 'previous' state is now
                            # the replaceState call from parent.
                            window.history.pushState {}, 'New Title', 'MyOtherPushUrl'
                            window.history.replaceState {}, 'New Title', 'MyOtherReplaceUrl'

                            runs ->
                                @popstateSpy = @spy()
                                ko.utils.registerEventHandler window, "popstate", @popstateSpy
                                
                                window.history.go -1

                            waits 400

                        it 'should raise a popstate event', ->
                            expect(@popstateSpy).toHaveBeenCalledOnce()

                        it 'should return to URL previously stored before replaceState', ->
                            expect(window.location.toString()).toContain 'MyNewUrl'

    beforeEach ->
        bo.location.reset()

    describe 'uri observables', ->
        it 'should have populated uri observable from current URL', ->
            expect(bo.location.uri).toBeObservable()

            # Use toContain as non-pushState browsers may have hash as well
            expect(bo.location.uri().toString()).toContain 'http://localhost'
            expect(bo.location.uri().toString()).toContain 'spec/runner.html'

        it 'should have populated host property from current URL', ->
            expect(bo.location.host()).toEqual 'localhost'

        it 'should have populated fragment observable from current URL', ->
            expect(bo.location.fragment).toBeObservable()
            expect(bo.location.fragment()).toEqual bo.location.uri().fragment

        it 'should have populated path observable from current URL', ->
            expect(bo.location.path).toBeObservable()
            expect(bo.location.path()).toEqual '/spec/runner.html'

        it 'should have populated variables observable from current URL', ->
            expect(bo.location.variables).toBeObservable()
            expect(bo.location.variables()).toEqual {}

        it 'should have populated query observable from current URL', ->
            expect(bo.location.query).toBeObservable()
            expect(bo.location.query()).toEqual ''

    describe 'and the URL changes through user action', ->
        beforeEach ->
            # pushState, then manually trigger popstate to simulate
            # a url being navigated to externally.
            window.history.pushState null, null, '/My New Url?key=value'            
            ko.utils.triggerEvent window, 'popstate'

        it 'should publish a urlChanged:external with current fragment and external=true', ->
            expect('urlChanged:external').toHaveBeenPublished()

            expect('urlChanged:external').toHaveBeenPublishedWith
                url: '/My New Url?key=value'
                path: '/My New Url'
                variables: { key: 'value' }
                external: true

        it 'should update the uri observable', ->
            expect(bo.location.uri().toString()).toContain '/My New Url'
            
        it 'should update the routePath observable', ->
            expect(bo.location.routePath()).toEqual '/My New Url'

        it 'should decode the routePath observable\'s value', ->
            expect(bo.location.routePath()).toEqual '/My New Url'

    describe 'setting URL', ->
        describe 'when changing the path to a new value', ->
            beforeEach ->
                @pushStateSpy = @spy window.history, 'pushState'
                bo.location.routePath '/Timesheets/Manage'

            it 'should use pushState to modify the URL', ->
                expect(@pushStateSpy).toHaveBeenCalledWith null, document.title, '/Timesheets/Manage'

            it 'should publish a urlChanged:internal message with current fragment and external=false', ->
                expect('urlChanged:internal').toHaveBeenPublished()

                expect('urlChanged:internal').toHaveBeenPublishedWith
                    url: '/Timesheets/Manage'
                    path: '/Timesheets/Manage'
                    variables: { }
                    external: false

            it 'should update the uri observable', ->
                expect(bo.location.uri().toString()).toContain '/Timesheets/Manage'

            it 'should update the routePath observable', ->
                expect(bo.location.routePath()).toEqual '/Timesheets/Manage'

        describe 'when passing the same URL', ->
            beforeEach ->
                @pushStateSpy = @spy window.history, 'pushState'
                @urlChangedMessageHandler = @spy()

                bo.bus.subscribe 'urlChanged:internal', @urlChangedMessageHandler

                # First time should raise events
                bo.location.routePath '/Users/Manage'
                bo.location.routePath '/Users/Manage'

            it 'should not push a new entry', ->
                expect(@pushStateSpy).toHaveBeenCalledOnce()

            it 'should not publish a urlChanged:internal message', ->
                expect(@urlChangedMessageHandler).toHaveBeenCalledOnce()

    describe 'setting state', ->
        describe 'when setting bookmarkable, history creating, key to a new value', ->
            beforeEach ->
                @pushStateSpy = @spy window.history, "pushState"
                @currentRoutePath = bo.location.routePath()

                @key = 'My Key'
                @value = 'Value' + (new Date()).getTime()

                bo.location.routeVariables.set @key, @value, { history: true }

            it 'should change URL to include key and value', ->
                # Anywhere in URL, as due to fallbacks is a little undefined as to where it
                # is placed
                expect(decodeURIComponent bo.location.uri().toString()).toContain "#{@key}=#{@value}"

            it 'should update variables observable to contain new value', ->
                expect(bo.location.routeVariables()[@key]).toEqual @value

            it 'should push a new history entry', ->
                expect(@pushStateSpy).toHaveBeenCalledOnce()

            it 'should not change the routePath observable', ->
                expect(bo.location.routePath()).toEqual @currentRoutePath 

        describe 'when setting bookmarkable, non history creating, key to a new value', ->
            beforeEach ->
                @replaceStateSpy = @spy window.history, "replaceState"
                @currentRoutePath = bo.location.routePath()

                @key = 'My Key'
                @value = 'Value' + (new Date()).getTime()

                bo.location.routeVariables.set @key, @value, { history: false }

            it 'should change URL to include key and value', ->
                # Anywhere in URL, as due to fallbacks is a little undefined as to where it
                # is placed
                expect(decodeURIComponent bo.location.uri().toString()).toContain "#{@key}=#{@value}"

            it 'should update variables observable to contain new value', ->
                expect(bo.location.routeVariables()[@key]).toEqual @value

            it 'should not push a new history entry', ->
                expect(@replaceStateSpy).toHaveBeenCalledOnce()

            it 'should not change the routePath observable', ->
                expect(bo.location.routePath()).toEqual @currentRoutePath 

#        describe 'when setting a variable with an onbeforeunload handler', ->
#            beforeEach ->
#                @onbeforeunloadStub = @stub().returns 'Are you sure you wish to navigate?'
#
#                window.onbeforeunload = @onbeforeunloadStub
#
#                @pushStateSpy = @spy window.history, "pushState"
#
#                bo.location.routeVariables.set 'My Key', 'My Value', { bookmark: true, history: true }
#
#            it 'should push a new history entry', ->
#                expect(@pushStateSpy).toHaveBeenCalledOnce()
#
#            it 'should not call onbeforeunload', ->
#                expect(@onbeforeunloadStub).toHaveNotBeenCalled()
#
#    describe 'preventing navigation', ->
#        describe 'when onbeforeunload handler has been registered that returns undefined', ->
#            beforeEach ->
#                window.onbeforeunload = ->
#                    undefined
#                        
#            describe 'when setting a new URL', ->
#                beforeEach ->
#                    @stub window.history, 'pushState'
#                    bo.location.routePath '/Users/Tim Smith/Edit'
#
#                it 'should not prevent setting a new URL', ->
#                    expect('urlChanged:internal').toHaveBeenPublished()
#
#                it 'should not prevent setting a new URL', ->
#                    expect('urlChanged:internal').toHaveBeenPublished()
#
#        describe 'when onbeforeunload handler has been registered that returns string', ->
#            beforeEach ->
#                window.onbeforeunload = ->
#                    'Are you sure you wish to navigate?'
#
#            afterEach ->
#                window.onbeforeunload = null
#
#            describe 'when user confirms they wish to navigate', ->
#                beforeEach ->
#                    # Cannot stub window.confirm directly as fails in IE7-8
#                    @savedConfirm = window.confirm
#                    window.confirm = @stub().returns true
#
#                afterEach ->
#                    window.confirm = @savedConfirm
#                        
#                describe 'when setting a new URL', ->
#                    beforeEach ->
#                        @stub window.history, 'pushState'
#                        @retValue = bo.location.routePath '/Users/List'
#
#                    it 'should not prevent setting a new URL', ->
#                        expect('urlChanged:internal').toHaveBeenPublished()
#
#                    it 'should return true', ->
#                        expect(@retValue).toBe true
#
#                    it 'should show a confirmation dialog', ->
#                        expect(window.confirm).toHaveBeenCalledOnce()
#                        expect(window.confirm).toHaveBeenCalledWith 'Are you sure you wish to navigate?'

#            describe 'when user cancels navigation', ->
#                beforeEach ->
#                    # Cannot stub window.confirm directly as fails in IE7-8
#                    @savedConfirm = window.confirm
#                    window.confirm = @stub().returns false
#
#                afterEach ->
#                    window.confirm = @savedConfirm
#                        
#                describe 'when setting a new URL', ->
#                    beforeEach ->
#                        @retValue = bo.location.routePath '/Users/Destroy'
#
#                    it 'should prevent setting a new URL', ->
#                        expect('urlChanged:internal').toHaveNotBeenPublished()
#
#                    it 'should return false', ->
#                        expect(@retValue).toBe false
#
#                    it 'should show a confirmation dialog', ->
#                        expect(window.confirm).toHaveBeenCalledOnce()
#                        expect(window.confirm).toHaveBeenCalledWith 'Are you sure you wish to navigate?'