describe 'Routing:', ->
    describe 'A route', ->
        describe 'with no definition', ->
            it 'should throw an exception on creation', ->
                creator = -> new bo.routing.Route '/My URL'
                expect(creator).toThrow "Argument 'definition' must be a string. 'undefined' was passed."

        describe 'when constructed', ->
            it 'should have a name property', ->
                # Act
                route = new bo.routing.Route 'Home', '/'

                # Assert
                expect(route.name).toEqual 'Home'

            it 'should have a definition property', ->
                # Act
                route = new bo.routing.Route 'Home', '/'

                # Assert
                expect(route.definition).toEqual '/'

        describe 'when navigateToRoute message published', ->
            it 'should raise a route navigating event with generated URL and itself as data', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/'

                # Act
                bo.bus.publish 'navigateToRoute:Home'

                # Assert
                expect('routeNavigating:Home').toHaveBeenPublishedWith { url: '/', route: homeRoute, canVeto: true }

        describe 'when a route is navigated to directly', ->
            it 'should raise a route navigating event with generated URL and itself as data', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/'

                # Act
                homeRoute.navigateTo()

                # Assert
                expect('routeNavigating:Home').toHaveBeenPublishedWith { url: '/', route: homeRoute, canVeto: true }

            it 'should not raise a route navigated event twice for the same route', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/'
                navigateSubscriber = @spy()

                bo.bus.subscribe 'routeNavigating:Home', navigateSubscriber

                # Act
                homeRoute.navigateTo()
                homeRoute.navigateTo()

                # Assert
                expect(navigateSubscriber).toHaveBeenCalledOnce()

            it 'should raise a route navigated event with generated URL and itself as data if routeNavigating publish is true', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/'
                navigateSubscriber = @spy()

                bo.bus.subscribe 'routeNavigated:Home', navigateSubscriber

                # Act
                homeRoute.navigateTo()

                # Assert
                expect(navigateSubscriber).toHaveBeenCalledWith
                    url: '/'
                    route: homeRoute
                    parameters: {}

            it 'should not raise a route navigated event if routeNavigating publish is false', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/'
                navigateSubscriber = @spy()
                routeNavigatingFalseReturner = @spy -> false

                bo.bus.subscribe 'routeNavigating', routeNavigatingFalseReturner
                bo.bus.subscribe 'routeNavigated', navigateSubscriber

                # Act
                homeRoute.navigateTo()

                # Assert
                expect(navigateSubscriber).toHaveNotBeenCalled()

            it 'should allow route navigation vetoing to be turned off', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/'
                navigateSubscriber = @spy()
                routeNavigatingFalseReturner = @spy -> false

                bo.bus.subscribe 'routeNavigating', routeNavigatingFalseReturner
                bo.bus.subscribe 'routeNavigated', navigateSubscriber

                # Act
                homeRoute.navigateTo {}, false

                # Assert
                expect(navigateSubscriber).toHaveBeenCalledOnce()

            it 'should indicate to routeNavigating subscribers their ability to veto', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/'
                navigateSubscriber = @spy()
                routeNavigatingFalseReturner = @spy -> false

                bo.bus.subscribe 'routeNavigating', navigateSubscriber

                # Act
                homeRoute.navigateTo {}, false

                # Assert
                expect(navigateSubscriber).toHaveBeenCalledWith { url: '/', route: homeRoute, canVeto: false }

        describe 'when a urlChanged message is published', ->
            it 'should publish a routeNavigated event if URL matches definition with no parameters', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/Home'

                # Act
                bo.bus.publish 'urlChanged', { url: '/Home' }

                # Assert
                expect('routeNavigated:Home').toHaveBeenPublishedWith 
                    url: '/Home', 
                    route: homeRoute
                    parameters: { }

            it 'should publish a routeNavigated event if URL matches definition with single parameter', ->
                # Arrange
                controllerRoute = new bo.routing.Route 'Controllers', '/{controller}'

                # Act
                bo.bus.publish 'urlChanged', { url: '/AController' }

                # Assert
                expect('routeNavigated:Controllers').toHaveBeenPublishedWith 
                    url: '/AController', 
                    route: controllerRoute
                    parameters: { controller: 'AController' }

            it 'should publish a routeNavigated event with fixed URL when no preceeding slash', ->
                # Arrange
                controllerRoute = new bo.routing.Route 'Controllers', '/{controller}'

                # Act
                bo.bus.publish 'urlChanged', { url: 'AController' }

                # Assert
                expect('routeNavigated:Controllers').toHaveBeenPublishedWith 
                    url: '/AController', 
                    route: controllerRoute
                    parameters: { controller: 'AController' }

            it 'should publish a routeNavigated event with fixed URL when following forward slash', ->
                # Arrange
                controllerRoute = new bo.routing.Route 'Controllers', '/{controller}'

                # Act
                bo.bus.publish 'urlChanged', { url: 'AController/' }

                # Assert
                expect('routeNavigated:Controllers').toHaveBeenPublishedWith 
                    url: '/AController', 
                    route: controllerRoute
                    parameters: { controller: 'AController' }

            it 'should publish a routeNavigated event if URL matches definition with multiple parameters', ->
                # Arrange
                controllerRoute = new bo.routing.Route 'Controllers', '/{controller}/{action}'

                # Act
                bo.bus.publish 'urlChanged', { url: '/AController/SomeAction' }

                # Assert
                expect('routeNavigated:Controllers').toHaveBeenPublishedWith 
                    url: '/AController/SomeAction', 
                    route: controllerRoute
                    parameters: { action: 'SomeAction', controller: 'AController' }

            it 'should publish a routeNavigated event if URL matches definition with splat parameter', ->
                # Arrange
                fileRoute = new bo.routing.Route 'File', '/File/{*filePath}'

                # Act
                bo.bus.publish 'urlChanged', { url: '/File/A/Long/File/Path/Name.png' }

                # Assert
                expect('routeNavigated:File').toHaveBeenPublishedWith 
                    url: '/File/A/Long/File/Path/Name.png', 
                    route: fileRoute
                    parameters: { filePath: 'A/Long/File/Path/Name.png' }

            it 'should not publish a routeNavigated event if URL does not match definition', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Controllers', '/Home'

                # Act
                bo.bus.publish 'urlChanged', { url: '/Contact Us' }

                # Assert
                expect('routeNavigated').toHaveNotBeenPublished()
                
    describe 'Routing Manager', ->
        bo.routing.manager.initialise()

        describe 'When statechange window event is triggered', ->
            it 'raises urlChanged event with current hash', ->
                # Arrange
                @stub window.History, 'getState', -> { hash: '/My Navigated URL' }

                # Act
                jQuery(window).trigger 'statechange'

                # Assert
                expect('urlChanged').toHaveBeenPublishedWith { url: '/My Navigated URL' }  

            it 'raises urlChanged event with current hash having period prefix removed', ->
                # Arrange
                @stub window.History, 'getState', -> { hash: './My Navigated URL' }

                # Act
                jQuery(window).trigger 'statechange'

                # Assert
                expect('urlChanged').toHaveBeenPublishedWith { url: '/My Navigated URL' }
