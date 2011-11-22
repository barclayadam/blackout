#reference '../../js/blackout/bo.bus.coffee'
#reference '../../js/blackout/bo.routing.coffee'

describe 'Routing:', ->
    describe 'Route', ->
        describe 'with no definition', ->
            it 'throws an exception', ->
                creator = -> new bo.routing.Route '/My URL'
                expect(creator).toThrow "Argument 'definition' must be a string. 'undefined' was passed."

        describe 'with no arguments', ->
            route = new bo.routing.Route 'Home', '/'

            it 'has a name property', ->
                expect(route.name).toEqual 'Home'

            it 'has a definition property', ->
                expect(route.definition).toEqual '/'

            it 'matches against definition URL with empty object as matched params', ->
                expect(route.match '/').toEqual {}

            it 'has an empty paramNames array', ->
                expect(route.paramNames.length).toBe 0
        
            it 'matches no other URL', ->
                expect(route.match '/Something').toBeUndefined()

            it 'constructs URL regardless of arguments passed in', ->
                expect(route.create()).toEqual '/'
                expect(route.create({ key: 'value' })).toEqual '/'
    
        describe 'with single argument', -> 
            route = new bo.routing.Route 'Home', '/{controller}'

            it 'matches against URL with no trailing slash', ->
                expect(route.match '/Something').toEqual { controller: 'Something' }

            it 'matches against URL with trailing slash', ->
                expect(route.match '/Something/').toEqual { controller: 'Something' }

            it 'has a paramNames array containing parameter', ->
                expect(route.paramNames).toContain 'controller'

            it 'does not construct URL when no arguments passed in', ->
                expect(route.create()).toBeUndefined()

            it 'constructs URL when named argument passed in', ->
                expect(route.create({ controller: 'MyController' })).toEqual '/MyController'
    
        describe 'with multiple arguments', -> 
            route = new bo.routing.Route 'Home', '/{controller}/{action}'

            it 'matches against URL with no trailing slash', ->
                expect(route.match '/Something/Else').toEqual { controller: 'Something', action: 'Else' }

            it 'matches against URL with trailing slash', ->            
                expect(route.match '/Something/Else/').toEqual { controller: 'Something', action: 'Else' }

            it 'has a paramNames array containing parameters', ->
                expect(route.paramNames).toContain 'controller'
                expect(route.paramNames).toContain 'action'

            it 'does not construct URL when no arguments passed in', ->
                expect(route.create()).toBeUndefined()

            it 'does not construct URL when too few arguments passed in', ->
                expect(route.create({ controller: 'MyController' })).toBeUndefined()

            it 'constructs URL when named argument passed in', ->
                expect(route.create({ controller: 'MyController', action: 'MyAction' })).toEqual '/MyController/MyAction'
    
        describe 'with splat parameter', -> 
            route = new bo.routing.Route 'Home', '/File/{*filePath}'

            it 'matches against URL with forward slashes within splat parameter', ->
                expect(route.match '/File/root/pictures/myPicture.png').toEqual { filePath: 'root/pictures/myPicture.png' }

            it 'has a paramNames array containing parameter', ->
                expect(route.paramNames).toContain 'filePath'

            it 'does not construct URL when no arguments passed in', ->
                expect(route.create()).toBeUndefined()
                
            it 'constructs URL when named argument passed in', ->
                expect(route.create({ filePath: 'root/pictures/myPicture.png' })).toEqual '/File/root/pictures/myPicture.png'

    describe 'RouteTable', ->
        beforeEach ->
            bo.routing.routes.clear()

        describe 'with no routes', ->
            it 'does not match any URL', ->
                expect(bo.routing.routes.match ('/')).toBeUndefined()
            
            it 'throws an exception when constructing a URL', ->
                creator = -> bo.routing.routes.create ('Home')
                expect(creator).toThrow "Cannot find the route 'Home'."

        describe 'with single route without parameters created explicity', ->
            beforeEach ->
                bo.routing.routes.add new bo.routing.Route 'Home', '/'

            it 'matches a URL that conforms to route', ->
                matchedRoute = bo.routing.routes.match '/'

                expect(matchedRoute.route.name).toEqual 'Home'
                expect(matchedRoute.parameters).toEqual {}
            
            it 'returns route definition when constructing named route', ->
                expect(bo.routing.routes.create 'Home').toEqual '/'

        describe 'with single route without parameters created implicitly', ->
            beforeEach ->
                bo.routing.routes.add 'Home', '/MyUrl'

            it 'matches a URL that conforms to route', ->
                matchedRoute = bo.routing.routes.match '/MyUrl'

                expect(matchedRoute.route.name).toEqual 'Home'
                expect(matchedRoute.parameters).toEqual {}
            
            it 'returns route definition when constructing named route', ->
                expect(bo.routing.routes.create 'Home').toEqual '/MyUrl'

        describe 'with single route with a parameter', ->
            beforeEach ->
                bo.routing.routes.add 'Home', '/{controller}'

            it 'will match single URL if incoming URL matches definition', ->
                matchedRoute = bo.routing.routes.match '/MyController'

                expect(matchedRoute.route.name).toEqual 'Home'
                expect(matchedRoute.parameters).toEqual {controller: 'MyController' }
                            
            it 'returns route definition when constructing named route with correct parameters', ->
                expect(bo.routing.routes.create 'Home', { controller: 'AController' } ).toEqual '/AController'

        describe 'with multiple routes with general route defined first', ->
            beforeEach ->
                bo.routing.routes.add 'Default', '/{controller}'
                bo.routing.routes.add 'Contact Us', '/Contact Us'

            it 'matches in the order added', ->
                matchedRoute = bo.routing.routes.match '/MyController'
                expect(matchedRoute.route.name).toEqual 'Default'
                expect(matchedRoute.parameters).toEqual {controller: 'MyController' }
                
                matchedRoute = bo.routing.routes.match '/Contact Us'
                expect(matchedRoute.route.name).toEqual 'Default'
                expect(matchedRoute.parameters).toEqual {controller: 'Contact Us' }
            
            it 'returns route definition when constructing named route with correct parameters', ->
                expect(bo.routing.routes.create 'Default', { controller: 'AController' } ).toEqual '/AController'
                expect(bo.routing.routes.create 'Contact Us' ).toEqual '/Contact Us'

        describe 'with multiple routes with specific route defined first', ->
            beforeEach ->
                bo.routing.routes.add 'Contact Us', '/Contact Us'
                bo.routing.routes.add 'Default', '/{controller}'

            it 'matches in the order added', ->
                matchedRoute = bo.routing.routes.match '/MyController'
                expect(matchedRoute.route.name).toEqual 'Default'
                expect(matchedRoute.parameters).toEqual {controller: 'MyController' }
                
                matchedRoute = bo.routing.routes.match '/Contact Us'
                expect(matchedRoute.route.name).toEqual 'Contact Us'
                expect(matchedRoute.parameters).toEqual { }
            
            it 'returns route definition when constructing named route with correct parameters', ->
                expect(bo.routing.routes.create 'Default', { controller: 'AController' } ).toEqual '/AController'
                expect(bo.routing.routes.create 'Contact Us' ).toEqual '/Contact Us'
                
    describe 'Router', ->
        describe 'When statechange window event is triggered', ->
            it 'raises UnknownUrlNavigatedTo event when hash does not corresponds to a route', ->
                # Arrange
                @stub window.History, 'getState', -> { hash: '/No Route URL', url: '/No Route URL' }
                spy = @spy bo.bus, 'publish'

                # Act
                $(window).trigger 'statechange'

                # Assert
                expect(spy).toHaveBeenCalledWith bo.routing.UnknownUrlNavigatedToEvent,  { url: '/No Route URL' }  

            it 'sets currentRoute observable to navigated to route', ->
                # Arrange
                bo.routing.routes.add 'Home', '/'
                @stub window.History, 'getState', -> { hash: '/' }

                # Act
                $(window).trigger 'statechange'

                # Assert
                expect(bo.routing.router.currentRoute().name).toEqual 'Home'

            it 'raises RouteNavigatedTo event when current has corresponds to known route', ->
                # Arrange
                bo.routing.routes.add 'Home', '/'

                @stub window.History, 'getState', -> { hash: '/' }
                spy = @spy bo.bus, 'publish'

                # Act
                $(window).trigger 'statechange'

                # Assert
                expect(spy).toHaveBeenCalledWith bo.routing.RouteNavigatedToEvent

            it 'raises RouteNavigatedTo event when current hash corresponds to known route, prefixed with a period', ->
                # Arrange
                bo.routing.routes.add 'Home', '/'

                @stub window.History, 'getState', -> { hash: './' }
                spy = @spy bo.bus, 'publish'

                # Act
                $(window).trigger 'statechange'

                # Assert
                expect(spy).toHaveBeenCalledWith bo.routing.RouteNavigatedToEvent
