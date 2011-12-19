describe 'RegionManager:', ->
    describe 'Creating a new region manager', ->
        beforeEach ->
            @manager = new bo.RegionManager()

        it 'has an observable current parts array property', ->
            expect(ko.isObservable @manager.currentParts).toBe true

        it 'has no current parts', ->
            expect(@manager.currentParts()).toEqual {}

    describe 'Activating a single registered part, when no current parts', ->
        beforeEach ->
            @manager = new bo.RegionManager()
            @homePart = new bo.Part 'Home', { templateName: 'dummy' }

        it 'adds the registered part to the currentParts array', ->
            # Arrange
            @stub @homePart, "activate", ->
                bo.utils.resolvedPromise()

            # Act
            @manager.activate [@homePart]

            # Assert
            expect(@manager.currentParts()['main']).toEqual @homePart

        it 'publishes a partsActivated message when all parts have been activated and promises resolved', ->
            # Arrange
            partsToActivate = [@homePart]

            # Act
            @manager.activate partsToActivate

            # Assert
            expect("partsActivating").toHaveBeenPublishedWith { parts: partsToActivate }

        it 'publishes a partsActivated message when all parts have been activated and promises resolved', ->
            # Arrange
            deferred = new jQuery.Deferred()

            activateStub = @stub @homePart, 'activate', ->
                [deferred.promise()]

            partsToActivate = [@homePart]

            # Act
            @manager.activate partsToActivate
            expect("partsActivated").toHaveNotBeenPublished()

            deferred.resolve()

            # Assert
            expect("partsActivated").toHaveBeenPublishedWith { parts: partsToActivate }

        it 'activates the registered part', ->
            activateSpy = @spy @homePart, 'activate'

            @manager.activate [@homePart]

            expect(activateSpy).toHaveBeenCalled()

        it 'does not set the currentParts array until all part promises are resolved successfully', ->
            # Arrange
            deferred = new jQuery.Deferred()

            activateStub = @stub @homePart, 'activate', ->
                [deferred.promise()]

            # Act
            @manager.activate [@homePart]

            expect(@manager.currentParts()).toEqual {}
            deferred.resolve()

            # Assert
            expect(@manager.currentParts()['main']).toBe @homePart

        it 'should set isLoading to true immediately', ->
            # Arrange
            deferred = new jQuery.Deferred()

            activateStub = @stub @homePart, 'activate', -> [deferred.promise()]

            # Act
            @manager.activate [@homePart]

            # Assert
            expect(@manager.isLoading()).toBe true

        it 'should set isLoading to false once all parts have finished activating', ->
            # Arrange
            deferred = new jQuery.Deferred()

            activateStub = @stub @homePart, 'activate', -> [deferred.promise()]

            # Act
            @manager.activate [@homePart]
            deferred.resolve()

            # Assert
            expect(@manager.isLoading()).toBe false

    describe 'Route changed event for multiple registered part, when no current parts', ->
        beforeEach ->
            @homePart = new bo.Part 'Home', { templateName: 'Dummy' }
            @helpPart = new bo.Part 'Help', { templateName: 'Dummy', region: 'help' }

            @manager = new bo.RegionManager()

        it 'should add the registered parts to the currentParts array', ->
            # Act
            @manager.activate [@homePart, @helpPart]

            # Assert
            expect(@manager.currentParts()['main']).toBe @homePart
            expect(@manager.currentParts()['help']).toBe @helpPart

        it 'should activate all the registered parts', ->
            # Arrange
            homePartActivateSpy = @spy @homePart, 'activate'
            helpPartActivateSpy = @spy @helpPart, 'activate'

            # Act
            @manager.activate [@homePart, @helpPart]

            # Assert
            expect(homePartActivateSpy).toHaveBeenCalled()
            expect(helpPartActivateSpy).toHaveBeenCalled()

        it 'should wait for all part promises to be resolved before updating currentParts array', ->
            # Arrange
            deferred1 = new jQuery.Deferred()
            deferred2 = new jQuery.Deferred()

            @stub @homePart, 'activate', -> deferred1.promise()
            @stub @helpPart, 'activate', -> deferred2.promise()

            # Act
            @manager.activate [@homePart, @helpPart]

            expect(@manager.currentParts()).toEqual {}
            deferred1.resolve()
            expect(@manager.currentParts()).toEqual {}
            deferred2.resolve()

            # Assert
            expect(@manager.currentParts()['main']).toBe @homePart
            expect(@manager.currentParts()['help']).toBe @helpPart

        it 'should set isLoading to true immediately', ->
            # Arrange
            deferred1 = new jQuery.Deferred()
            deferred2 = new jQuery.Deferred()

            @stub @homePart, 'activate', -> deferred1.promise()
            @stub @helpPart, 'activate', -> deferred2.promise()

            # Act
            @manager.activate [@homePart, @helpPart]

            # Assert
            expect(@manager.isLoading()).toBe true

        it 'should set isLoading to false once all parts have finished activating', ->
            # Arrange
            deferred1 = new jQuery.Deferred()
            deferred2 = new jQuery.Deferred()

            @stub @homePart, 'activate', -> deferred1.promise()
            @stub @helpPart, 'activate', -> deferred2.promise()

            # Act
            @manager.activate [@homePart, @helpPart]
            deferred1.resolve()
            expect(@manager.isLoading()).toBe true
            deferred2.resolve()

            # Assert
            expect(@manager.isLoading()).toBe false

    describe 'Route changed event for single registered part, when current parts exist', ->
        beforeEach ->
            @homePart = new bo.Part 'Home', { viewModel: { isDirty: false }, templateName: 'Dummy' }
            @contactUsPart = new bo.Part 'Contact Us', { viewModel: { isDirty: false }, templateName: 'Dummy' }

            @manager = new bo.RegionManager()

        it 'returns true as subscriber to "routeNavigating" if no current part is dirty', ->
            # Arrange
            @manager.activate [@homePart]
            expect(@manager.currentParts()['main']).toBe @homePart

            # Act
            canChange = bo.bus.publish "routeNavigatingTo", { route: { name: 'Contact Us' }}

            # Assert
            expect(canChange).toEqual true

        it 'returns result of confirm as subscriber to "routeNavigatingTo" if any current part returns true from isDirty', ->
            # Arrange
            expectedCanChange = true
            @stub window, "confirm", -> expectedCanChange

            @homePart.viewModel.isDirty = true

            @manager.activate [@homePart]
            expect(@manager.currentParts()['main']).toBe @homePart

            # Act
            canChange = bo.bus.publish "routeNavigatingTo", { route: { name: 'Contact Us' }}

            # Assert
            expect(canChange).toEqual expectedCanChange

        it 'calls deactivate of registered parts', ->
            # Ensure onSuccess always called
            deactivateSpy = @spy @homePart, "deactivate"

            # Arrange
            @manager.activate [@homePart]
            expect(@manager.currentParts()['main']).toBe @homePart

            # Act
            @manager.activate [@contactUsPart]

            # Assert
            expect(deactivateSpy).toHaveBeenCalled()

        it 'changes if no current part is dirty', ->
            # Arrange
            @manager.activate [@homePart]
            expect(@manager.currentParts()['main']).toBe @homePart

            # Act
            @manager.activate [@contactUsPart]

            # Assert
            expect(@manager.currentParts()['main']).toBe @contactUsPart

        it 'activates all registered parts of route', ->
            contactUsActivateSpy = @spy @contactUsPart, "activate"

            # Arrange
            @manager.activate [@homePart]
            expect(@manager.currentParts()['main']).toBe @homePart

            # Act
            @manager.activate [@contactUsPart]

            # Assert
            expect(contactUsActivateSpy).toHaveBeenCalled()

    describe 'When reactivate event occurs when current parts exist', ->
        beforeEach ->
            @homePart = new bo.Part 'Home', { templateName: 'Dummy' }
            @manager = new bo.RegionManager()

        it 'reactivates all current parts with parameters', ->
            # Arrange
            parameters = { id: 67 }
            homeActivateSpy = @spy @homePart, 'activate'
            @manager.activate [@homePart], parameters

            expect(homeActivateSpy).toHaveBeenCalled()

            # Act
            bo.bus.publish 'reactivateParts'

            # Assert
            expect(homeActivateSpy.getCall(1).args[0]).toEqual parameters

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
        beforeEach ->
            @homePart = new bo.Part 'Home', { templateName: 'Dummy' }
            @contactUsPart = new bo.Part 'Contact Us', { templateName: 'Dummy' }

            @manager = new bo.RegionManager()

        it 'should re-render the anonymous template', ->
            # Arrange
            anonymousTemplate = """<div class='main' />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            @manager.activate [@homePart]

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
            @manager.activate [@homePart]

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
            @manager.activate [@homePart]

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
            @manager.activate [@homePart]
            @manager.activate [@contactUsPart]

            # Assert
            expect(initSpy.callCount).toBe 2

        it 'should apply the is-loading class when isLoading', ->
            # Arrange
            @stub @homePart, "activate", -> new jQuery.Deferred().promise()

            anonymousTemplate = """<div class='main' />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            @manager.activate [@homePart]

            # Assert
            expect(@manager.isLoading()).toBe true
            expect(managerDiv).toHaveClass 'is-loading'

        it 'should remove the is-loading class once all current parts have been activated', ->
            # Arrange
            deferred = new jQuery.Deferred()

            @stub @homePart, "activate", -> deferred.promise()

            anonymousTemplate = """<div class='main' />"""
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager">#{anonymousTemplate}</div>""").appendTo(@fixture)
            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            @manager.activate [@homePart]
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
            @homePart = new bo.Part 'Home', { templateName: 'Dummy' }

            @manager = new bo.RegionManager()

        it 'should not render the DOM node to which it is attached', ->
            # Arrange
            managerDiv = jQuery("""<div data-bind="regionManager: regionManager"><div data-bind="region: 'non-active-region'" /></div>""").appendTo(@fixture)

            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            @manager.activate [@homePart]

            # Assert
            expect(managerDiv).toBeEmpty()

    describe 'When referenced part is active within the regionManager', ->
        beforeEach ->
            @homePartViewModel = { myData: 'Something interesting'}
            @homePart = new bo.Part 'Home', { templateName: 'HomePartTemplate', viewModel: @homePartViewModel }

            @manager = new bo.RegionManager()

        it 'should render the part template as a child DOM element', ->
            # Arrange
            homePartTemplate = """<div><span>Hello, is it me you're looking for?</span></div>"""
            managerDiv = jQuery("""<div>
                                     <div id="HomePartTemplate">#{homePartTemplate}</div>
                                     <div id="regionManagerContainer" data-bind="regionManager: regionManager"><div data-bind="region: 'main'" /></div>
                                   </div>""").appendTo(@fixture)

            ko.applyBindings({ regionManager: @manager }, @fixture[0])

            # Act
            @manager.activate [@homePart]

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
            @manager.activate [@homePart]

            # Assert
            expect(boundViewModel).toBe @homePartViewModel