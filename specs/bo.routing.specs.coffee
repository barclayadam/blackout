describe 'Routing:', ->
    beforeEach ->
        bo.routing.Route.currentUrl = undefined    

    describe 'A route', ->
        describe 'with no definition', ->
            it 'should throw an exception on creation', ->
                creator = -> new bo.routing.Route '/My URL'
                expect(creator).toThrow "Argument 'definition' must be a string. 'undefined' was passed."

        describe 'when constructed with name and definition only', ->
            beforeEach ->
                @route = new bo.routing.Route 'Home', '/'

            it 'should have a name property', ->
                expect(@route.name).toEqual 'Home'

            it 'should have a definition property', ->
                expect(@route.definition).toEqual '/'

            it 'should have a title property set to the name of the route', ->
                expect(@route.title).toEqual 'Home'

            it 'should have an empty metadata property', ->
                expect(@route.metadata).toEqual {}

        describe 'when constructed with options', ->
            beforeEach ->
                @metadata = 
                    metadata: 
                        aMetadataProperty: 5 

                @options = 
                    metadata: @metadata
                    title: 'My Custom Title'

                @route = new bo.routing.Route 'Home', '/', @options

            it 'should store options in options property', ->
                expect(@route.options).toBe @options

            it 'should set metadata property from options object', ->
                expect(@route.metadata).toBe @metadata

            it 'should override title from options object', ->
                expect(@route.title).toEqual 'My Custom Title'

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

            it 'should raise a route navigated event with generated URL and itself as data', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/'

                # Act
                homeRoute.navigateTo()

                # Assert
                expect('routeNavigated:Home').toHaveBeenPublishedWith
                    url: '/'
                    route: homeRoute
                    parameters: {}

            it 'should not raise a route navigated event if routeNavigating subscriber returns false', ->
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

            it 'should use single parameter when creating URL representation when navigateTo called', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/{aParam}'

                # Act
                homeRoute.navigateTo { aParam: 'A Value' }

                # Assert
                expect('routeNavigating:Home').toHaveBeenPublishedWith 
                    url: '/A Value', 
                    route: homeRoute, 
                    canVeto: true

            it 'should use single observable parameter when creating URL representation when navigateTo called', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/{aParam}'

                # Act
                homeRoute.navigateTo { aParam: ko.observable('A Value') }

                # Assert
                expect('routeNavigating:Home').toHaveBeenPublishedWith 
                    url: '/A Value', 
                    route: homeRoute, 
                    canVeto: true

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

            it 'should not publish a routeNotFound event if URL matches', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Home', '/Home'

                # Act
                bo.bus.publish 'urlChanged', { url: '/Home' }

                # Assert
                expect('routeNotFound').toHaveNotBeenPublishedWith()

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

            it 'should publish a routeNavigated event if url does not contain a preceeding forward slash but route specifies one', ->
                # Arrange
                controllerRoute = new bo.routing.Route 'Controllers', '/Controller/{action}'

                # Act
                bo.bus.publish 'urlChanged', { url: 'Controller/MyAction' }

                # Assert
                expect('routeNavigated:Controllers').toHaveBeenPublishedWith 
                    url: '/Controller/MyAction', 
                    route: controllerRoute
                    parameters: { action: 'MyAction' }

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

            it 'should not publish a routeNavigated message when no routes match', ->
                # Arrange
                homeRoute = new bo.routing.Route 'Controllers', '/Home'

                # Act
                bo.bus.publish 'urlChanged', { url: '/Contact Us' }

                # Assert
                expect('routeNavigated').toHaveNotBeenPublished()

            it 'should publish a routeNotFound message when no routes match', ->
                # Act
                bo.bus.publish 'urlChanged', { url: '/Contact Us' }

                # Assert
                expect('routeNotFound').toHaveBeenPublishedWith
                    url: '/Contact Us'
            
    describe 'navigateTo binding handler', ->
        it 'should publish a navigateToRoute message when clicked', ->
            # Arrange
            navigateLink = @setHtmlFixture("""<a href='#' data-bind="navigateTo: 'Home'">Home</a>""")

            @applyBindingsToHtmlFixture { }

            # Act
            navigateLink.click()

            # Assert
            expect("navigateToRoute:Home").toHaveBeenPublishedWith
                name: 'Home'
                parameters: {}
                canVeto: true
                forceNavigate: false

        it 'should not publish a navigateToRoute message when clicked if enabled binding handler evaluates to false', ->
            # Arrange
            navigateLink = @setHtmlFixture("""<a href='#' data-bind="navigateTo: 'Home', enabled: false">Home</a>""")

            @applyBindingsToHtmlFixture { }

            # Act
            navigateLink.click()

            # Assert
            expect("navigateToRoute:Home").toHaveNotBeenPublished()

        it 'should not publish a navigateToRoute message when clicked if disabled binding handler evaluates to true', ->
            # Arrange
            navigateLink = @setHtmlFixture("""<a href='#' data-bind="navigateTo: 'Home', disabled: true">Home</a>""")

            @applyBindingsToHtmlFixture { }

            # Act
            navigateLink.click()

            # Assert
            expect("navigateToRoute:Home").toHaveNotBeenPublished()

        it 'should publish a navigateToRoute message with canVeto set from canVeto binding value', ->
            # Arrange
            navigateLink = @setHtmlFixture("""<a href='#' data-bind="navigateTo: 'Home', canVeto: false">Home</a>""")

            @applyBindingsToHtmlFixture { }

            # Act
            navigateLink.click()

            # Assert
            expect("navigateToRoute:Home").toHaveBeenPublishedWith
                name: 'Home'
                canVeto: false
                forceNavigate: false
                parameters: {}

        it 'should publish a navigateToRoute message when forceNavigate is set to true when navigating to the current page', ->
            # Arrange
            homeRoute = new bo.routing.Route 'Home', '/'
            navigateSubscriber = @spy()

            bo.bus.subscribe 'routeNavigating:Home', navigateSubscriber

            # Act
            bo.routing.navigateTo 'Home', {}, false, false
            bo.routing.navigateTo 'Home', {}, false, true

            # Assert
            expect(navigateSubscriber).toHaveBeenCalled(2)

        it 'should not publish a navigateToRoute message when forceNavigate is set to false when navigating to the current page', ->
            # Arrange
            homeRoute = new bo.routing.Route 'Home', '/'
            navigateSubscriber = @spy()

            bo.bus.subscribe 'routeNavigating:Home', navigateSubscriber

            # Act
            bo.routing.navigateTo 'Home', {}, false, false
            bo.routing.navigateTo 'Home', {}, false, false

            # Assert
            expect(navigateSubscriber).toHaveBeenCalledOnce()

        it 'should publish a navigateToRoute message with parameters set from parameters binding value', ->
            # Arrange
            navigateLink = @setHtmlFixture("""<a href='#' data-bind="navigateTo: 'Home', parameters: { id : 6 }">Home</a>""")

            @applyBindingsToHtmlFixture { }

            # Act
            navigateLink.click()

            # Assert
            expect("navigateToRoute:Home").toHaveBeenPublishedWith
                name: 'Home'
                canVeto: true
                forceNavigate: false
                parameters: { id : 6 }