(itShouldReturnMatchedRoute = (options) ->
    describe "by #{options.name}", ->
        beforeEach ->
            @matchedRoute = @router.getRouteFromUrl options.inputUrl

        it 'should return the matched route data', ->
            expect(@matchedRoute).toBeDefined

        it 'should have route populated as expected', ->
            expect(@matchedRoute.route.name).toEqual options.route

        it 'should have parameters populated as expected', ->
            expect(@matchedRoute.parameters).toEqual options.expectedParameters
)

describe 'Routing:', ->
    beforeEach ->
        @router = new bo.routing.Router()

    describe 'No routes defined', ->
        describe 'getting a route that does not exist (URL)', ->
            beforeEach ->
                @matchedRoute = @router.getRouteFromUrl '/An unknown url'

            it 'should return undefined', ->
                expect(@matchedRoute).toBeUndefined

        describe 'getting a route that does not exist (name)', ->
            beforeEach ->
                @route = @router.getNamedRoute 'Unknown Route'

            it 'should return undefined', ->
                expect(@route).toBeUndefined()

        describe 'URL changed by user', ->
            beforeEach ->
                bo.bus.publish 'urlChanged:external', 
                    url: '/404'
                    external: true

            it 'should publish a routeNotFound message', ->
                expect('routeNotFound').toHaveBeenPublishedWith
                    url: '/404'

    describe 'Single no-param route', ->
        beforeEach ->
            @routeNavigatedStub = @stub()
            @router.route 'Contact Us', '/Contact Us', @routeNavigatedStub
            @contactUsRoute = @router.getNamedRoute 'Contact Us'

        it 'should default title of route to the name', ->
            expect(@contactUsRoute.title).toEqual 'Contact Us'

        describe 'getting the route by name', ->
            beforeEach ->
                @route = @router.getNamedRoute 'Contact Us'

            it 'should return the route', ->
                expect(@route).toBeDefined()
                expect(@route.name).toBe 'Contact Us'

        describe 'URL changed externally to one matching route', ->
            beforeEach ->
                bo.bus.publish 'urlChanged:external', 
                    url: '/Contact Us'
                    external: true

            it 'should call registered callback with parameters', ->
                expect(@routeNavigatedStub).toHaveBeenCalledWith {}

            it 'should publish a routeNavigated message', ->
                expect("routeNavigated:Contact Us").toHaveBeenPublishedWith
                    route: @contactUsRoute
                    parameters: {}

        describe 'URL changed by user to not match URL', ->
            beforeEach ->
                bo.bus.publish 'urlChanged:external', 
                    url: '/Some URL That Does Not Exist'
                    external: true

            it 'should publish a routeNotFound message', ->
                expect('routeNotFound').toHaveBeenPublishedWith
                    url: '/Some URL That Does Not Exist'

        describe 'navigateTo route', ->
            describe 'once', ->
                beforeEach ->                
                    @routePathStub = @stub bo.location, 'routePath'
                    @router.navigateTo 'Contact Us'

                afterEach ->
                    document.title = @currentTitle

                it 'should use history manager to push a built URL', ->
                    expect(@routePathStub).toHaveBeenCalledWith '/Contact Us'

                it 'should call registered callback with parameters', ->
                    expect(@routeNavigatedStub).toHaveBeenCalledWith {}

                it 'should publish a routeNavigated message', ->
                    expect("routeNavigated:Contact Us").toHaveBeenPublishedWith
                        route: @contactUsRoute
                        parameters: {}

            describe 'twice consecutively', ->
                beforeEach ->                
                    @routeNavigatedStub = @stub()
                    bo.bus.subscribe 'routeNavigated', @routeNavigatedStub

                    @routePathStub = @stub bo.location, 'routePath'
                    @router.navigateTo 'Contact Us'
                    @router.navigateTo 'Contact Us'

                afterEach ->
                    document.title = @currentTitle

                it 'should change location.routePath twice', ->
                    expect(@routePathStub).toHaveBeenCalledTwice()

                it 'should call registered callback with parameters again', ->
                    expect(@routeNavigatedStub).toHaveBeenCalledTwice()

                it 'should publish a routeNavigated message twice', ->
                    expect(@routeNavigatedStub).toHaveBeenCalledTwice()

        describe 'getting route from URL', ->
            itShouldReturnMatchedRoute 
                name: 'exact match URL with no query string' 
                inputUrl: '/Contact Us'
                expectedParameters: {}
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'exact match encoded URL' 
                inputUrl: '/Contact%20Us'
                expectedParameters: {}
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'relative URL with missing slash at start' 
                inputUrl: 'Contact Us/'
                expectedParameters: {}
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'URL with query string parameters' 
                inputUrl: '/Contact Us/?key=prop'
                expectedParameters: {}
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'URL with different casing' 
                inputUrl: '/CoNTact US/?key=prop'
                expectedParameters: {}
                route: 'Contact Us'

    describe 'Multiple, different, routes', ->
        beforeEach ->
            @contactUsRouteNavigatedStub = @stub()
            @aboutUsRouteNavigatedStub = @stub()

            @router.route 'Contact Us', '/Contact Us', @contactUsRouteNavigatedStub
            @router.route 'About Us', '/About Us', @aboutUsRouteNavigatedStub

            @contactUsRoute = @router.getNamedRoute 'Contact Us'
            @aboutUsRoute = @router.getNamedRoute 'About Us'

        describe 'URL changed externally to one matching route', ->
            beforeEach ->
                bo.bus.publish 'urlChanged:external', 
                    url: '/Contact Us'
                    external: true

            it 'should call registered callback with parameters', ->
                expect(@contactUsRouteNavigatedStub).toHaveBeenCalledWith {}

            it 'should not call registered callbacks of other routes', ->
                expect(@aboutUsRouteNavigatedStub).toHaveNotBeenCalled()

            it 'should publish a routeNavigated message', ->
                expect("routeNavigated:Contact Us").toHaveBeenPublishedWith
                    route: @contactUsRoute
                    parameters: {}

        describe 'URL changed by user to not match URL', ->
            beforeEach ->
                bo.bus.publish 'urlChanged:external', 
                    url: '/Some URL That Does Not Exist'
                    external: true

            it 'should publish a routeNavigated message', ->
                expect('routeNotFound').toHaveBeenPublishedWith
                    url: '/Some URL That Does Not Exist'

        describe 'navigateTo route', ->
            describe 'switch between two routes', ->
                beforeEach ->                
                    @routePathStub = @stub bo.location, 'routePath'

                    @router.navigateTo 'Contact Us'
                    @router.navigateTo 'About Us'
                    @router.navigateTo 'Contact Us'

                afterEach ->
                    document.title = @currentTitle

                it 'should change location.routePath all three times', ->
                    expect(@routePathStub).toHaveBeenCalledWith '/Contact Us'
                    expect(@routePathStub).toHaveBeenCalledWith '/About Us'

                    expect(@routePathStub).toHaveBeenCalledThrice()                    

                it 'should publish routeNavigated messages', ->
                    expect("routeNavigated:Contact Us").toHaveBeenPublishedWith
                        route: @contactUsRoute
                        parameters: {}

                    expect("routeNavigated:About Us").toHaveBeenPublishedWith
                        route: @aboutUsRoute
                        parameters: {}

        describe 'getting route from URL', ->
            itShouldReturnMatchedRoute 
                name: 'exact match URL for first route' 
                inputUrl: '/Contact Us'
                expectedParameters: {}
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'exact match URL for second route' 
                inputUrl: '/About Us'
                expectedParameters: {}
                route: 'About Us'

    describe 'Multiple routes that match the same URL', ->
        beforeEach ->
            @router.route 'Contact Us', '/Contact Us'
            @router.route 'Contact Us 2', '/Contact Us'

            @contactUsRoute = @router.getNamedRoute 'Contact Us'
            @contactUs2Route = @router.getNamedRoute 'Contact Us 2'

        describe 'URL changed externally to one matching route', ->
            beforeEach ->
                bo.bus.publish 'urlChanged:external', 
                    url: '/Contact Us'
                    external: true

            it 'should publish a routeNavigated message for last registered route', ->
                expect("routeNavigated:Contact Us 2").toHaveBeenPublishedWith
                    route: @contactUs2Route
                    parameters: {}

        describe 'getting route from URL', ->
            itShouldReturnMatchedRoute 
                name: 'exact match URL to match last route registered' 
                inputUrl: '/Contact Us'
                expectedParameters: {}
                route: 'Contact Us 2'

    describe 'Single one-param route', ->
        beforeEach ->
            @routeNavigatedStub = @stub()
            @router.route 'Contact Us', '/Contact Us/{category}', @routeNavigatedStub
            @contactUsRoute = @router.getNamedRoute 'Contact Us'

        describe 'URL changed externally to one matching route', ->
            beforeEach ->
                bo.bus.publish 'urlChanged:external', 
                    url: '/Contact Us/A Category'
                    external: true

            it 'should call registered callback with parameters', ->
                expect(@routeNavigatedStub).toHaveBeenCalledWith { category: 'A Category' }

            it 'should publish a routeNavigated message', ->
                expect("routeNavigated:Contact Us").toHaveBeenPublishedWith
                    route: @contactUsRoute
                    parameters: { category: 'A Category' }

        describe 'navigateTo route', ->
            describe 'twice consecutively with same parameters', ->
                beforeEach ->                
                    @routeNavigatedStub = @stub()
                    bo.bus.subscribe 'routeNavigated', @routeNavigatedStub

                    @routePathStub = @stub bo.location, 'routePath'
                    @router.navigateTo 'Contact Us', { category: 'A Category' }
                    @router.navigateTo 'Contact Us', { category: 'A Category' }

                afterEach ->
                    document.title = @currentTitle

                it 'should change routePath twice', ->
                    expect(@routePathStub).toHaveBeenCalledTwice()

                it 'should call registered callback with parameters twice', ->
                    expect(@routeNavigatedStub).toHaveBeenCalledTwice()

                it 'should publish a routeNavigated message twice', ->
                    expect(@routeNavigatedStub).toHaveBeenCalledTwice()

            describe 'twice consecutively with different parameters', ->
                beforeEach ->                
                    @routeNavigatedStub = @stub()
                    bo.bus.subscribe 'routeNavigated', @routeNavigatedStub

                    @routePathStub = @stub bo.location, 'routePath'
                    @router.navigateTo 'Contact Us', { category: 'A Category' }
                    @router.navigateTo 'Contact Us', { category: 'A Different Category' }

                afterEach ->
                    document.title = @currentTitle

                it 'should change routePath twice', ->
                    expect(@routePathStub).toHaveBeenCalledTwice()

                it 'should call registered callback with parameters twice', ->
                    expect(@routeNavigatedStub).toHaveBeenCalledTwice()

                it 'should publish a routeNavigated message twice', ->
                    expect(@routeNavigatedStub).toHaveBeenCalledTwice()

        describe 'creating a URL from the named route', ->
            beforeEach ->
                @url = @router.buildUrl 'Contact Us', { category : 'A Category' }

            it 'should return the url with parameter', ->
                expect(@url).toEqual '/Contact Us/A Category'

        describe 'creating a URL from the named route with observable values', ->
            beforeEach ->
                @url = @router.buildUrl 'Contact Us', { category : ko.observable 'A Category' }

            it 'should return the url with unwrapped parameter', ->
                expect(@url).toEqual '/Contact Us/A Category'

        describe 'getting route from URL', ->
            itShouldReturnMatchedRoute 
                name: 'exact match URL with no query string' 
                inputUrl: '/Contact Us/My Category'
                expectedParameters: { category: 'My Category' }
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'extra trailing slash and no query string' 
                inputUrl: '/Contact Us/My Category/'
                expectedParameters: { category: 'My Category' }
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'exact match encoded URL' 
                inputUrl: '/Contact%20Us/My%20Category'
                expectedParameters: { category: 'My Category' }
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'relative URL with missing slash at start' 
                inputUrl: 'Contact Us/My Category'
                expectedParameters: { category: 'My Category' }
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'URL with query string parameters' 
                inputUrl: '/Contact Us/My Category?key=prop'
                expectedParameters: { category: 'My Category' }
                route: 'Contact Us'

    describe 'Single two-param route', ->
        beforeEach ->
            @router.route 'Contact Us', '/Contact Us/{category}/{param2}'
            @contactUsRoute = @router.getNamedRoute 'Contact Us'

        describe 'creating a URL from the named route', ->
            beforeEach ->
                @url = @router.buildUrl 'Contact Us', 
                    category : 'A Category', 
                    param2: 'A Value'

            it 'should return the url with parameter', ->
                expect(@url).toEqual '/Contact Us/A Category/A Value'

        describe 'getting route from URL', ->
            itShouldReturnMatchedRoute 
                name: 'exact match URL with no query string' 
                inputUrl: '/Contact Us/My Category/Other'
                expectedParameters: { param2: 'Other', category: 'My Category' }
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'extra trailing slash and no query string' 
                inputUrl: '/Contact Us/My Category/Other/'
                expectedParameters: {  param2: 'Other', category: 'My Category' }
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'exact match encoded URL' 
                inputUrl: '/Contact%20Us/My%20Category/Other'
                expectedParameters: {  param2: 'Other', category: 'My Category' }
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'relative URL with missing slash at start' 
                inputUrl: 'Contact Us/My Category/Other'
                expectedParameters: {  param2: 'Other', category: 'My Category' }
                route: 'Contact Us'

            itShouldReturnMatchedRoute 
                name: 'URL with query string parameters' 
                inputUrl: '/Contact Us/My Category/Other?key=prop'
                expectedParameters: {  param2: 'Other', category: 'My Category' }
                route: 'Contact Us'

    describe 'Single one-param catch-all route', ->
        beforeEach ->
            @router.route 'File', '/File/{*path}'
            @fileRoute = @router.getNamedRoute 'File'

        describe 'creating a URL from the named route', ->
            beforeEach ->
                @url = @router.buildUrl 'File', 
                    path: 'my/path/file.png'

            it 'should return the url with parameter', ->
                expect(@url).toEqual '/File/my/path/file.png'

        describe 'creating a URL from the named route with optional param missing', ->
            beforeEach ->
                @url = @router.buildUrl 'File', {}

            it 'should return the url with parameter', ->
                expect(@url).toEqual '/File/'

        describe 'getting route from URL', ->
            itShouldReturnMatchedRoute 
                name: 'exact match URL with no query string' 
                inputUrl: '/File/my/path/file.png'
                expectedParameters: { path: 'my/path/file.png' }
                route: 'File'

            itShouldReturnMatchedRoute 
                name: 'extra trailing slash and no query string' 
                inputUrl: '/File/my/path/file.png/'
                expectedParameters: { path: 'my/path/file.png/' }
                route: 'File'

            itShouldReturnMatchedRoute 
                name: 'exact match encoded URL' 
                inputUrl: '/File/my/path/my%20file.png'
                expectedParameters: { path: 'my/path/my file.png' }
                route: 'File'

            itShouldReturnMatchedRoute 
                name: 'relative URL with missing slash at start' 
                inputUrl: 'File/my/path/file.png'
                expectedParameters: { path: 'my/path/file.png' }
                route: 'File'

            itShouldReturnMatchedRoute 
                name: 'URL with query string parameters' 
                inputUrl: '/File/my/path/file.png?key=prop'
                expectedParameters: { path: 'my/path/file.png' }
                route: 'File'

            itShouldReturnMatchedRoute 
                name: 'Missing optional parameter' 
                inputUrl: '/File/'
                expectedParameters: { path: '' }
                route: 'File'