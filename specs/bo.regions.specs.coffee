describe 'RegionManager:', ->
    describe 'Creating a new region manager', ->
        beforeEach ->
            @manager = new bo.RegionManager()

        it 'has an observable current parts array property', ->
            expect(ko.isObservable @manager.currentParts).toBe true

        it 'has no current parts', ->
            expect(@manager.currentParts()).toEqual {}

    describe 'Registering a part', ->
        it 'throws an exception if route does not exist', ->
            @manager = new bo.RegionManager()
            register = => @manager.register 'Unknown Route', (new bo.Part 'Home')

            expect(register).toThrow "Cannot find route with name 'Unknown Route'"

    describe 'Route changed event raised with no corresponding page', ->
        beforeEach ->
            @manager = new bo.RegionManager()

        it 'does not change the current page', ->
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: (new bo.routing.Route 'Unknown', '/Somewhere'), parameters: {} }
            expect(@manager.currentParts()).toEqual {}

    describe 'Route changed event for single registered part, when no current parts', ->
        homePart = undefined

        beforeEach ->
            bo.routing.routes.add 'Home', '/'

            @manager = new bo.RegionManager()
            homePart = new bo.Part 'Home', { templateName: 'dummy' }
            @manager.register 'Home', homePart

        it 'adds the registered part to the currentParts array', ->
            # Arrange
            @stub homePart, "activate", ->
                bo.utils.resolvedPromise()

            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()['main']).toEqual homePart

        it 'activates the registered part', ->
            activateSpy = @spy homePart, 'activate'

            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}

            expect(activateSpy).toHaveBeenCalled()

        it 'does not activate parts again when same route navigated to', ->
            activateSpy = @spy homePart, 'activate'

            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}

            expect(activateSpy).toHaveBeenCalledOnce()

        it 'does not set the currentParts array until all part promises are resolved successfully', ->
            # Arrange
            deferred = new jQuery.Deferred()

            activateStub = @stub homePart, 'activate', ->
                [deferred.promise()]

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()).toEqual {}
            deferred.resolve()

            # Assert
            expect(@manager.currentParts()['main']).toBe homePart

        it 'should set isLoading to true immediately', ->
            # Arrange
            deferred = new jQuery.Deferred()

            activateStub = @stub homePart, 'activate', -> [deferred.promise()]

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}

            # Assert
            expect(@manager.isLoading()).toBe true

        it 'should set isLoading to false once all parts have finished activating', ->
            # Arrange
            deferred = new jQuery.Deferred()

            activateStub = @stub homePart, 'activate', -> [deferred.promise()]

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            deferred.resolve()

            # Assert
            expect(@manager.isLoading()).toBe false

    describe 'Route changed event for multiple registered part, when no current parts', ->
        homePart = new bo.Part 'Home', { templateName: 'Dummy' }
        helpPart = new bo.Part 'Help', { templateName: 'Dummy', region: 'help' }

        beforeEach ->
            bo.routing.routes.add 'Home', '/'

            @manager = new bo.RegionManager()
            @manager.register 'Home', homePart
            @manager.register 'Home', helpPart

        it 'should add the registered parts to the currentParts array', ->
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()['main']).toBe homePart
            expect(@manager.currentParts()['help']).toBe helpPart

        it 'should activate all the registered parts', ->
            homePartActivateSpy = @spy homePart, 'activate'
            helpPartActivateSpy = @spy helpPart, 'activate'

            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}

            expect(homePartActivateSpy).toHaveBeenCalled()
            expect(helpPartActivateSpy).toHaveBeenCalled()

        it 'should wait for all part promises to be resolved before updating currentParts array', ->
            # Arrange
            deferred1 = new jQuery.Deferred()
            deferred2 = new jQuery.Deferred()

            @stub homePart, 'activate', -> deferred1.promise()
            @stub helpPart, 'activate', -> deferred2.promise()

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()).toEqual {}
            deferred1.resolve()
            expect(@manager.currentParts()).toEqual {}
            deferred2.resolve()

            # Assert
            expect(@manager.currentParts()['main']).toBe homePart
            expect(@manager.currentParts()['help']).toBe helpPart

        it 'should set isLoading to true immediately', ->
            # Arrange
            deferred1 = new jQuery.Deferred()
            deferred2 = new jQuery.Deferred()

            @stub homePart, 'activate', -> deferred1.promise()
            @stub helpPart, 'activate', -> deferred2.promise()

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}

            # Assert
            expect(@manager.isLoading()).toBe true

        it 'should set isLoading to false once all parts have finished activating', ->
            # Arrange
            deferred1 = new jQuery.Deferred()
            deferred2 = new jQuery.Deferred()

            @stub homePart, 'activate', -> deferred1.promise()
            @stub helpPart, 'activate', -> deferred2.promise()

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            deferred1.resolve()
            expect(@manager.isLoading()).toBe true
            deferred2.resolve()

            # Assert
            expect(@manager.isLoading()).toBe false

    describe 'Route changed event for single registered part, when current parts exist', ->
        homePart = null
        contactUsPart = null

        beforeEach ->
            bo.routing.routes.add 'Home', '/'
            bo.routing.routes.add 'Contact Us', '/Contact Us'

            homePart = new bo.Part 'Home', { viewModel: { isDirty: false }, templateName: 'Dummy' }
            contactUsPart = new bo.Part 'Contact Us', { viewModel: { isDirty: false }, templateName: 'Dummy' }

            @manager = new bo.RegionManager()
            @manager.register 'Home', homePart
            @manager.register 'Contact Us', contactUsPart

        it 'returns true as subscriber to bo.routing.RouteNavigatingToEvent if no current part is dirty', ->
            # Arrange
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()['main']).toBe homePart

            # Act
            canChange = bo.bus.publish bo.routing.RouteNavigatingToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(canChange).toEqual true

        it 'returns result of confirm as subscriber to bo.routing.RouteNavigatingToEvent if any current part returns true from isDirty', ->
            # Arrange
            expectedCanChange = true
            @stub window, "confirm", -> expectedCanChange

            homePart.viewModel.isDirty = true

            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()['main']).toBe homePart

            # Act
            canChange = bo.bus.publish bo.routing.RouteNavigatingToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(canChange).toEqual expectedCanChange

        it 'calls deactivate of registered parts', ->
            # Ensure onSuccess always called
            deactivateSpy = @spy homePart, "deactivate"

            # Arrange
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()['main']).toBe homePart

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(deactivateSpy).toHaveBeenCalled()

        it 'changes if no current part is dirty', ->
            # Arrange
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()['main']).toBe homePart

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(@manager.currentParts()['main']).toBe contactUsPart

        it 'activates all registered parts of route', ->
            contactUsActivateSpy = @spy contactUsPart, "activate"

            # Arrange
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' }}
            expect(@manager.currentParts()['main']).toBe homePart

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' }}

            # Assert
            expect(contactUsActivateSpy).toHaveBeenCalled()

    describe 'When reactivate event occurs when current parts exist', ->
        homePart = new bo.Part 'Home', { templateName: 'Dummy' }
        contactUsPart = new bo.Part 'Contact Us', { templateName: 'Dummy' }

        beforeEach ->
            bo.routing.routes.add 'Home', '/'
            bo.routing.routes.add 'Contact Us', '/Contact Us'

            @manager = new bo.RegionManager()
            @manager.register 'Home', homePart
            @manager.register 'Contact Us', contactUsPart

        it 'reactivates all current parts with current route parameters', ->
            # Arrange
            contactUsActivateSpy = @spy contactUsPart, 'activate'
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' }, parameters: { id: 6 } }

            expect(contactUsActivateSpy).toHaveBeenCalled()

            # Act
            bo.bus.publish bo.RegionManager.reactivateEvent

            # Assert
            expect(contactUsActivateSpy.getCall(1).args[0]).toEqual { id: 6 }

describe 'RegionManager Binding Handler', ->
    describe 'When a RegionManager has no current parts', ->
        it 'should render no child content', ->
            # Arrange
            manager = new bo.RegionManager()
            managerDiv = jQuery('<div data-bind="regionManager: regionManager" />').appendTo(@fixture)

            # Act
            ko.applyBindings({ regionManager: manager }, @fixture[0])

            # Assert
            expect(managerDiv).toBeEmpty()

        it 'should render nothing to replace existing child content', ->
            # Arrange
            manager = new bo.RegionManager()
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager"><div data-bind="region: 'main'" /></div>""").appendTo(@fixture)

            # Act
            ko.applyBindings({ regionManager: manager }, @fixture[0])

            # Assert
            expect(managerDiv).toBeEmpty()

        it 'should not call the init function of any bindingHandler', ->
            # Arrange
            manager = new bo.RegionManager()
            initSpy = @spy()

            ko.bindingHandlers.testRegionManager =
                init: initSpy

            anonymousTemplate = """<div data-bind="testRegionManager: true" />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)

            # Act
            ko.applyBindings({ regionManager: manager }, @fixture[0])

            # Assert
            expect(initSpy).toHaveNotBeenCalled()

    describe 'When a route is navigated to', ->
        homePart = new bo.Part 'Home', { templateName: 'Dummy' }
        contactUsPart = new bo.Part 'Contact Us', { templateName: 'Dummy' }

        beforeEach ->
            bo.routing.routes.add 'Home', '/'
            bo.routing.routes.add 'Contact Us', '/Contact Us'

            @manager = new bo.RegionManager()
            @manager.register 'Home', homePart
            @manager.register 'Contact Us', contactUsPart

        it 'should re-render the anonymous template', ->
            # Arrange
            anonymousTemplate = """<div class='main' />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }

            # Assert
            expect(managerDiv).toHaveHtml anonymousTemplate

        it 'should set the regionManager as the viewModel when binding the anonymous template', ->
            # Arrange
            boundViewModel = null

            ko.bindingHandlers.testRegionManager =
                init: (element, valueAccessor, allBindingAccessors, viewModel) ->
                    boundViewModel = viewModel

            anonymousTemplate = """<div data-bind="testRegionManager: true" />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }

            # Assert
            expect(boundViewModel).toEqual @manager

        it 'should call the init function of each bindingHandler once for a route change', ->
            # Arrange
            initSpy = @spy()

            ko.bindingHandlers.testRegionManager =
                init: initSpy

            anonymousTemplate = """<div data-bind="testRegionManager: true" />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }

            # Assert
            expect(initSpy).toHaveBeenCalledOnce()

        it 'should call the init function of each bindingHandler for every route change', ->
            # Arrange
            initSpy = @spy()

            ko.bindingHandlers.testRegionManager =
                init: initSpy

            anonymousTemplate = """<div data-bind="testRegionManager: true" />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Contact Us' } }

            # Assert
            expect(initSpy.callCount).toBe 2

        it 'should apply the is-loading class when isLoading', ->
            # Arrange
            @stub homePart, "activate", -> new jQuery.Deferred().promise()

            anonymousTemplate = """<div class='main' />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }

            # Assert
            expect(@manager.isLoading()).toBe true
            expect(managerDiv).toHaveClass 'is-loading'

        it 'should remove the is-loading class once all current parts have been activated', ->
            # Arrange
            deferred = new jQuery.Deferred()

            @stub homePart, "activate", -> deferred.promise()

            anonymousTemplate = """<div class='main' />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }
            expect(managerDiv).toHaveClass 'is-loading'
            deferred.resolve()

            # Assert
            expect(@manager.isLoading()).toBe false
            expect(managerDiv).toNotHaveClass 'is-loading'

describe 'Region Binding Handler', ->
    describe 'When region binding used without enclosing regionManager binding', ->
        it 'should throw an exception', ->
            # Arrange
            jQuery("""<div data-bind="region: 'main'" />""").appendTo(@fixture)

            # Act
            result = => ko.applyBindings({ }, @fixture[0])

            # Assert
            expect(result).toThrow 'A region binding must be enclosed within a regionManager binding.'

    describe 'When referenced part is not active within the regionManager', ->
        beforeEach ->
            bo.routing.routes.add 'Home', '/'

            @manager = new bo.RegionManager()
            @manager.register 'Home', new bo.Part 'Home', { templateName: 'Dummy' }

        it 'should not render the DOM node to which it is attached', ->
            # Arrange
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager"><div data-bind="region: 'non-active-region'" /></div>""").appendTo(@fixture)

            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }

            # Assert
            expect(managerDiv).toBeEmpty()

    describe 'When referenced part is active within the regionManager', ->
        beforeEach ->
            bo.routing.routes.add 'Home', '/'

            @homePartViewModel = { myData: 'Something interesting'}
            @homePart = new bo.Part 'Home', { templateName: 'HomePartTemplate', viewModel: @homePartViewModel }

            @manager = new bo.RegionManager()
            @manager.register 'Home', @homePart

        it 'should render the part template as a child DOM element', ->
            # Arrange
            homePartTemplate = """<div><span>Hello, is it me you're looking for?</span></div>"""
            managerDiv = jQuery("""<div>
                                     <div id="HomePartTemplate">#{homePartTemplate}</div>
                                     <div id="regionManagerContainer" data-bind="regionManager: regionManager"><div data-bind="region: 'main'" /></div>
                                   </div>""").appendTo(@fixture)

            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }

            # Assert
            expect(managerDiv.find("#regionManagerContainer")).toHaveHtml """<div data-bind="region: 'main'">#{homePartTemplate}</div>"""

        it 'should render the part template with the part viewModel', ->
            # Arrange
            boundViewModel = null

            ko.bindingHandlers.testRegion =
                init: (element, valueAccessor, allBindingAccessor, viewModel) ->
                    boundViewModel = viewModel

            homePartTemplate = """<div id="HomePartTemplate" data-bind="testRegion: true" />"""
            managerDiv = jQuery("""<div id="HomePartTemplate">#{homePartTemplate}</div>
                                   <div data-bind="regionManager: regionManager">
                                     <div data-bind="region: 'main'" />
                                   </div>""").appendTo(@fixture)

            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            bo.bus.publish bo.routing.RouteNavigatedToEvent, { route: { name: 'Home' } }

            # Assert
            expect(boundViewModel).toBe @homePartViewModel