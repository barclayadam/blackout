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
            
        it 'should have a title property conventionally set to the name of the part', ->
            expect(homePage.title).toEqual 'Home'

        it 'should have a template path property conventionally set to the name of the part', ->
            expect(homePage.templatePath).toEqual '/Templates/Get/Home'

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
            resetSpy = @spy()
            homePage = new bo.Part 'Home', { viewModel: { isDirty: true, reset: resetSpy } }

            # Act
            homePage.activate {}   

            # Assert
            expect(resetSpy).toHaveBeenCalledOnce()

        it 'should publish a namespaced partActivating message', ->
            # Arrange
            homePage = new bo.Part 'Home', { viewModel: {} }

            # Act
            homePage.activate {}   

            # Assert
            expect('partActivating:Home').toHaveBeenPublished()

        it 'should publish a namespaced partActivated message when all promises resolved', ->
            # Arrange
            @respondWithTemplate 'HomeTmpl', '<div id="test" />'

            homePage = new bo.Part 'Home', { viewModel: {}, templatePath: 'HomeTmpl' }

            promises = homePage.activate {}    
            expect('partActivated:Home').toHaveNotBeenPublished()

            # Act                    
            @server.respond()

            # Assert
            expect('partActivated:Home').toHaveBeenPublished()

        it 'should return an array', ->
            # Arrange
            homePage = new bo.Part 'Home', { viewModel: { }, templatePath: '/server/whatever' }
            @stub bo.utils, 'addTemplate', ->

            @respondWithTemplate '/server/whatever', '<div id="test" />'

            # Act
            promiseArray = homePage.activate {}
            @server.respond()

            # Assert
            expect(promiseArray).toBeDefined()
            expect(promiseArray).toBeAnArray()

        describe 'with a template path', ->
            it 'should load the template from the server using the path', ->
                # Arrange
                homePage = new bo.Part 'Home', { viewModel: { }, templatePath: '/server/whatever' }
                addTemplateSpy = @stub bo.utils, 'addTemplate', ->

                @respondWithTemplate '/server/whatever', '<div id="test" />'

                # Act
                homePage.activate {}
                @server.respond()

                # Assert
                expect(addTemplateSpy).toHaveBeenCalledWith 'Part-Home', '<div id="test" />'

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