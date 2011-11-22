#reference '../../js/blackout/bo.bus.coffee'
#reference '../../js/blackout/bo.routing.coffee'
#reference '../../js/blackout/bo.parts.coffee'

describe 'Parts:', ->
    describe 'Newly created part without a model', ->
        homePage = new bo.Part 'Home'

        it 'should have a canDeactivate function which returns true', ->
            expect(homePage.canDeactivate()).toEqual true

        it 'should have a deactivate function', ->
            expect(homePage.deactivate).toBeDefined()
            expect($.isFunction homePage.deactivate).toBe true

        it 'should have an activate function', ->
            expect(homePage.activate).toBeDefined()
            expect($.isFunction homePage.activate).toBe true

        it 'should have a name property equal to the first parameter', ->
            expect(homePage.name).toEqual 'Home'
            
        it 'should have a title property conventionally set to the pages name', ->
            expect(homePage.title).toEqual 'Home'

        it 'should have a template name property conventionally set to the pages name', ->
            expect(homePage.templateName).toEqual 'Home'

    describe 'When creating a part with a model that has an isDirty view model property', ->   
        it 'returns negated value of viewModel isDirty property when asked if canDeactivate', ->
            # Act
            homePage = new bo.Part 'Home', { viewModel: { isDirty: true } }

            # Assert
            expect(homePage.canDeactivate()).toEqual false

        it 'returns negated value of isDirty observable property when asked if canDeactivate', ->
            # Act
            homePage = new bo.Part 'Home', { viewModel: { isDirty: ko.observable false } }

            # Assert
            expect(homePage.canDeactivate()).toEqual true

    describe 'When activating a part', ->   
        it 'should call the reset function of the viewModel', ->
            # Arrange
            @respondWithTemplate 'Home', '<div id="test" />'

            resetSpy = @spy()
            homePage = new bo.Part 'Home', { viewModel: { isDirty: true, reset: resetSpy } }

            # Act
            homePage.activate {}            
            @server.respond()

            # Assert
            expect(resetSpy).toHaveBeenCalledOnce()

    describe 'When activating a part with a realised instance of a viewModel', ->   
        it 'should call the initialise function of the viewModel', ->
            # Arrange
            initSpy = @spy()
            homePage = new bo.Part 'Home', { viewModel: { isDirty: true, initialise: initSpy } }

            # Act
            homePage.activate {}

            # Assert
            expect(initSpy).toHaveBeenCalledOnce()

        it 'should not call the initialise function of the viewModel on reactivation', ->
            # Arrange
            initSpy = @spy()
            homePage = new bo.Part 'Home', { viewModel: { isDirty: true, initialise: initSpy } }

            # Act
            homePage.activate {}
            homePage.activate {}

            # Assert
            expect(initSpy).toHaveBeenCalledOnce()

    describe 'When activating a part with function for creating the view model', ->   
        it 'should call the initialise function of the viewModel', ->
            # Arrange
            initSpy = @spy()
            homePage = new bo.Part 'Home', { viewModel: -> { isDirty: true, initialise: initSpy } }

            # Act
            homePage.activate {}

            # Assert
            expect(initSpy).toHaveBeenCalledOnce()

        it 'should always call the initialise function of the viewModel on reactivation', ->
            # Arrange
            initSpy = @spy()
            homePage = new bo.Part 'Home', { viewModel: -> { isDirty: true, initialise: initSpy } }

            # Act
            homePage.activate {}
            homePage.activate {}

            # Assert
            expect(initSpy).toHaveBeenCalledTwice()
            
describe 'PartManager:', ->
    manager = null

    describe 'Creating a new part manager', ->
        beforeEach ->
            manager = new bo.PartManager()

        it 'has an observable current parts array property', ->
            expect(ko.isObservable manager.currentParts).toBe true

        it 'has no current parts', ->
            expect(manager.currentParts().length).toBe 0

    describe 'Registering a part', ->
        it 'throws an exception if route does not exist', ->
            manager = new bo.PartManager()            
            register = -> manager.register 'Unknown Route', (new bo.Part 'Home')

            expect(register).toThrow "Cannot find route with name 'Unknown Route'"

    describe 'Route changed event raised with no corresponding page', ->
        beforeEach ->
            manager = new bo.PartManager()

        it 'does not change the current page', ->
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: (new bo.routing.Route 'Unknown', '/Somewhere'), parameters: {} }
            expect(manager.currentParts().length).toBe 0

    describe 'Route changed event for single registered part, when no current parts', ->        
        homePage = undefined
            
        beforeEach ->
            bo.routing.routes.add 'Home', '/'

            manager = new bo.PartManager()
            homePage = new bo.Part 'Home'
            manager.register 'Home', homePage

        it 'adds the registered part to the currentParts array', ->
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(manager.currentParts()[0].name).toEqual 'Home'	

        it 'activates the registered part', ->
            activateSpy = @spy homePage, 'activate'
            
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            
            expect(activateSpy).toHaveBeenCalled()			

        it 'does not activate parts again when same route navigated to', ->
            activateSpy = @spy homePage, 'activate'
            
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            
            expect(activateSpy).toHaveBeenCalledOnce()

    describe 'Route changed event for multiple registered part, when no current parts', -> 
        homePage = new bo.Part 'Home'
        helpPart = new bo.Part 'Help'

        beforeEach ->
            bo.routing.routes.add 'Home', '/'

            manager = new bo.PartManager()
            manager.register 'Home', homePage
            manager.register 'Home', helpPart

        it 'adds the registered parts to the currentParts array', ->
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(manager.currentParts()).toContain homePage
            expect(manager.currentParts()).toContain helpPart			

        it 'activates all the registered parts', ->
            homePageActivateSpy = @spy homePage, 'activate'
            helpPartActivateSpy = @spy helpPart, 'activate'
            
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            
            expect(homePageActivateSpy).toHaveBeenCalled()	
            expect(helpPartActivateSpy).toHaveBeenCalled()	

    describe 'Route changed event for single registered part, when current parts exist', ->
        homePage = null
        contactUsPage = null

        beforeEach ->
            bo.routing.routes.add 'Home', '/'
            bo.routing.routes.add 'Contact Us', '/Contact Us'
            
            homePage = new bo.Part 'Home', { viewModel: { isDirty: false } }
            contactUsPage = new bo.Part 'Contact Us', { viewModel: { isDirty: false } }

            manager = new bo.PartManager()
            manager.register 'Home', homePage
            manager.register 'Contact Us', contactUsPage
            
        it 'returns true as subscriber to bo.routing.RouteNavigatingToEvent if no current part is dirty', ->
            # Arrange
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(manager.currentParts()[0].name).toEqual 'Home'

            # Act
            canChange = bo.bus.publish bo.routing.RouteNavigatingToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(canChange).toEqual true

        it 'returns result of confirm as subscriber to bo.routing.RouteNavigatingToEvent if any current part returns true from isDirty', ->
            # Arrange
            expectedCanChange = true
            @stub window, "confirm", -> expectedCanChange

            homePage.viewModel.isDirty = true

            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(manager.currentParts()[0].name).toEqual 'Home'

            # Act
            canChange = bo.bus.publish bo.routing.RouteNavigatingToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(canChange).toEqual expectedCanChange

        it 'calls deactivate of registered parts', ->
            # Ensure onSuccess always called
            deactivateSpy = @spy homePage, "deactivate"

            # Arrange
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(manager.currentParts()[0].name).toEqual 'Home'

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(deactivateSpy).toHaveBeenCalled()

        it 'changes if no current part is dirty', ->
            # Arrange
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(manager.currentParts()[0].name).toEqual 'Home'

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(manager.currentParts()[0].name).toEqual 'Contact Us'

        it 'activates all registered parts of route', ->
            contactUsActivateSpy = @spy contactUsPage, "activate"

            # Arrange
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(manager.currentParts()[0].name).toEqual 'Home'

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(contactUsActivateSpy).toHaveBeenCalled()

    describe 'When reactivate event occurs when current parts exist', ->
        homePage = new bo.Part 'Home'
        contactUsPage = new bo.Part 'Contact Us'

        beforeEach ->
            bo.routing.routes.add 'Home', '/'
            bo.routing.routes.add 'Contact Us', '/Contact Us'

            manager = new bo.PartManager()
            manager.register 'Home', homePage
            manager.register 'Contact Us', contactUsPage

        it 'reactivates all current parts with current route parameters', ->
            # Arrange
            contactUsActivateSpy = @spy contactUsPage, 'activate'
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' }, parameters: { id: 6 } }

            expect(contactUsActivateSpy).toHaveBeenCalled()

            # Act
            bo.bus.publish bo.PartManager.reactivateEvent

            # Assert
            expect(contactUsActivateSpy.getCall(1).args[0]).toEqual { id: 6 }
