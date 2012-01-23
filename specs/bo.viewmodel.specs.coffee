#reference "../../js/blackout/bo.utils.coffee"

describe 'ViewModels', ->
    describe 'When creating a new view model', ->
        it 'should have a canSubmit observable that is initially false', ->
            # Act
            viewModel = new bo.ViewModel()

            # Assert
            expect(viewModel.canSubmit).toBeObservable()
            expect(viewModel.canSubmit()).toBe false

        it 'should have a isDirty observable that is initially false', ->
            # Act
            viewModel = new bo.ViewModel()

            # Assert
            expect(viewModel.isDirty).toBeObservable()
            expect(viewModel.isDirty()).toBe false
                    
        it 'should have a commandsToSubmit observable that is initially an empty array', ->
            # Act
            viewModel = new bo.ViewModel()

            # Assert
            expect(viewModel.commandsToSubmit).toBeObservable()
            expect(viewModel.commandsToSubmit()).toEqual []
            
    describe 'When submitting', ->
        it 'should not submit if isDirty is false', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.isDirty false
            

            validateStub = @stub viewModel, "validate", -> # Do nothing, keep viewModel valid
            commandSpy = @spy bo.messaging, 'command'
            commandBatchSpy = @spy bo.messaging, 'commands'

            # Act
            viewModel.submit()

            # Assert
            expect(commandSpy).toHaveNotBeenCalled()
            expect(commandBatchSpy).toHaveNotBeenCalled()

        it 'should validate values that have been "set"', ->
            # Arrange
            command = new bo.Command 'My Command', 
                  myProperty: undefined

            viewModel = new bo.ViewModel()
            viewModel.isDirty true
            viewModel.set 'command', command
            viewModel.getCommandsToSubmit = -> [command]

            validateSpy = @spy bo.validation, "validate"

            # Act
            viewModel.submit()

            # Assert
            expect(validateSpy).toHaveBeenCalled()

        it 'should not submit if commandToSubmit is not valid', ->
            # Arrange
            command = new bo.Command 'My Command', 
                  myProperty: ko.observable(undefined).validatable { required: true }

            viewModel = new bo.ViewModel()
            viewModel.isDirty true
            viewModel.set 'command', command
            viewModel.getCommandsToSubmit = -> [command]

            commandSpy = @spy bo.messaging, 'command'
            commandBatchSpy = @spy bo.messaging, 'commands'

            # Act
            viewModel.submit()

            # Assert
            expect(commandSpy).toHaveNotBeenCalled()
            expect(commandBatchSpy).toHaveNotBeenCalled()

        it 'should not submit if no commandToSubmit exists and isDirty is true', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.isDirty true            

            validateStub = @stub viewModel, "validate", -> # Do nothing, keep viewModel valid
            commandSpy = @spy bo.messaging, 'command'
            commandBatchSpy = @spy bo.messaging, 'commands'

            # Act
            viewModel.submit()

            # Assert
            expect(commandSpy).toHaveNotBeenCalled()
            expect(commandBatchSpy).toHaveNotBeenCalled()

        it 'should send single commandToSubmit if only one exists and isDirty is true', ->
            # Arrange
            command = new bo.Command 'Command 1', {}
                        
            class TestVM extends bo.ViewModel
                getCommandsToSubmit: -> [command]

            viewModel = new TestVM()
            viewModel.isDirty true
            viewModel.set 'command', command

            commandStub = @stub bo.messaging, 'command', -> new jQuery.Deferred().promise()

            # Act
            viewModel.submit()

            # Assert
            expect(commandStub).toHaveBeenCalledWith command

        it 'should send single batched command set if multiple commands in commandToSubmit and isDirty is true', ->
            # Arrange
            command1 = new bo.Command 'Command 1', {}
            command2 = new bo.Command 'Command 2', {}

            class TestVM extends bo.ViewModel
                getCommandsToSubmit: -> [command1, command2]

            viewModel = new TestVM()
            viewModel.isDirty true
            viewModel.set 'command1', command1
            viewModel.set 'command2', command2

            commandStub = @stub bo.messaging, 'commands', -> new jQuery.Deferred().promise()

            # Act
            viewModel.submit()

            # Assert
            expect(commandStub).toHaveBeenCalledWith [command1, command2]

        it 'should call onSubmitSuccess when command submit is successful and isDirty is true', ->
            # Arrange
            command = new bo.Command 'Command 1', {}
            
            class TestVM extends bo.ViewModel
                getCommandsToSubmit: -> [command]

            viewModel = new TestVM()
            viewModel.isDirty true
            viewModel.set 'command', command
            viewModel.onSubmitSuccess = @spy()

            deferred = new jQuery.Deferred()

            commandStub = @stub bo.messaging, 'command', -> deferred.promise()

            # Act
            viewModel.submit()
            deferred.resolve()

            # Assert
            expect(viewModel.onSubmitSuccess).toHaveBeenCalled()
            
        it 'should set itself as not dirty after a successful submit', ->
            # Arrange
            command = new bo.Command 'Command 1', {}
            
            class TestVM extends bo.ViewModel
                getCommandsToSubmit: -> [command]

            viewModel = new TestVM()
            viewModel.isDirty true
            viewModel.set 'command', command
            viewModel.onSubmitSuccess = @spy()

            deferred = new jQuery.Deferred()

            commandStub = @stub bo.messaging, 'command', -> deferred.promise()

            # Act
            viewModel.submit()
            deferred.resolve()

            # Assert
            expect(viewModel.isDirty()).toBe false

    describe 'When setting values', ->
        it 'should create multiple observables if calling setAll', ->
            # Arrange
            viewModel = new bo.ViewModel()

            # Act
            viewModel.setAll
                'myProperty': true
                'myOtherProperty': false

            # Assert
            expect(viewModel.myProperty).toBeObservable()
            expect(viewModel.myProperty()).toBe true

            expect(viewModel.myOtherProperty).toBeObservable()
            expect(viewModel.myOtherProperty()).toBe false

        it 'should create an observable if value is not an array with given initial value', ->
            # Arrange
            viewModel = new bo.ViewModel()

            # Act
            viewModel.set 'myProperty', true

            # Assert
            expect(viewModel.myProperty).toBeObservable()
            expect(viewModel.myProperty()).toBe true
            
        it 'should return created observable from set call', ->
            # Arrange
            viewModel = new bo.ViewModel()

            # Act
            observable = viewModel.set 'myProperty', true

            # Assert
            expect(observable).toBe viewModel.myProperty

        it 'should create an observable array if value is an array with given initial value', ->
            # Arrange
            viewModel = new bo.ViewModel()

            # Act
            viewModel.set 'myProperty', []

            # Assert
            expect(viewModel.myProperty).toBeObservable()
            # Check for a known array method
            expect(viewModel.myProperty.remove).toBeDefined()

        it 'should update an existing observable if same property name given', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.set 'myProperty', true

            subscription = @spy()
            viewModel.myProperty.subscribe subscription
            
            # Act
            viewModel.set 'myProperty', false

            # Assert
            expect(viewModel.myProperty()).toBe false
            expect(subscription).toHaveBeenCalled()

        it 'should create an observable that is registered for dirty tracking', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.set 'myProperty', true
            
            expect(viewModel.isDirty()).toBe false

            # Act
            viewModel.myProperty false

            # Assert
            expect(viewModel.isDirty()).toBe true
            
        it 'should register all observables of object graph when setting value', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.set 'myProperty', { myChildProperty: ko.observable() }
            
            expect(viewModel.isDirty()).toBe false

            # Act
            viewModel.myProperty().myChildProperty false

            # Assert
            expect(viewModel.isDirty()).toBe true

        it 'should register all observables of object graph that are not plain objects', ->
            # Arrange
            class MyType
                 constructor: ->
                    @childProperty = ko.observable()

            viewModel = new bo.ViewModel()
            viewModel.set 'myProperty', new MyType()
            
            expect(viewModel.isDirty()).toBe false

            # Act
            viewModel.myProperty().childProperty false

            # Assert
            expect(viewModel.isDirty()).toBe true

        it 'should set isDirty to false on reset', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.set 'myProperty', true
            viewModel.set 'myProperty', false

            expect(viewModel.isDirty()).toEqual true

            # Act
            viewModel.reset()

            # Assert
            expect(viewModel.isDirty()).toEqual false

    describe 'When evaluating canSubmit', ->
        it 'should set canSubmit to true when isDirty is true and there are commandsToSubmit', ->
            # Arrange
            class TestVM extends bo.ViewModel
                getCommandsToSubmit: ->  [ new bo.Command 'Command 1' ]

            viewModel = new TestVM()
            viewModel.set 'myProperty', true

            # Act
            viewModel.myProperty false

            # Assert
            expect(viewModel.isDirty()).toEqual true
            expect(viewModel.canSubmit()).toEqual true

        it 'should set canSubmit to false when isDirty is true and there are no commandsToSubmit', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.set 'myProperty', true
            

            # Act
            viewModel.myProperty false

            # Assert
            expect(viewModel.isDirty()).toEqual true
            expect(viewModel.canSubmit()).toEqual false

        it 'should set canSubmit to false when isDirty is false and there are no commandsToSubmit', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.set 'myProperty', true
            

            # Assert
            expect(viewModel.isDirty()).toEqual false
            expect(viewModel.canSubmit()).toEqual false

        it 'should set canSubmit to false when isDirty is false and there are commandsToSubmit', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.set 'myProperty', true
            viewModel.getCommandsToSubmit = -> [ new bo.Command 'Command 1' ]

            # Assert
            expect(viewModel.isDirty()).toEqual false
            expect(viewModel.canSubmit()).toEqual false

    describe 'When observables registered for dirty tracking', ->
        it 'should do nothing if a non-observable is registered for dirty tracking', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.nonObservableProperty = 73563
            
            # Act
            viewModel.registerForDirtyTracking viewModel.nonObservableProperty

        it 'should set isDirty to true when only registered observable changes its value', ->
            # Arrange
            viewModel = new bo.ViewModel()
            observable = ko.observable()

            viewModel.registerForDirtyTracking observable

            # Act
            observable 4515

            # Assert
            expect(viewModel.isDirty()).toBe true

        it 'should set isDirty to true when any observable properties change their value', ->
            # Arrange
            viewModel = new bo.ViewModel()
            observable1 = ko.observable()
            observable2 = ko.observable()

            viewModel.registerForDirtyTracking observable1
            viewModel.registerForDirtyTracking observable2

            # Act
            observable2 4515

            # Assert
            expect(viewModel.isDirty()).toBe true

        it 'should set isDirty to true when child observable property of registered model (observable) changes', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.model = ko.observable
                childProperty: ko.observable()

            viewModel.registerForDirtyTracking viewModel.model

            # Act
            viewModel.model().childProperty 4515

            # Assert
            expect(viewModel.isDirty()).toBe true

        it 'should set isDirty to true when child observable property or registered model (non observable) changes', ->
            # Arrange
            viewModel = new bo.ViewModel()
            viewModel.model =
                childProperty: ko.observable()

            viewModel.registerForDirtyTracking viewModel.model

            # Act
            viewModel.model.childProperty 4515

            # Assert
            expect(viewModel.isDirty()).toBe true

    describe 'When validating', ->
        it 'should validate a registered value with a validate method', ->
            # Arrange
            command = new bo.Command 'My Command'
            validateSpy = @spy command, 'validate'

            viewModel = new bo.ViewModel
            viewModel.set 'myCommand', command
            
            # Act
            viewModel.validate()

            # Assert
            expect(validateSpy).toHaveBeenCalledOnce()

        it 'should not fail if a value that has been set does not have a validate method', ->
            # Arrange
            command = new bo.Command 'My Command'
            validateSpy = @spy command, 'validate'

            viewModel = new bo.ViewModel
            viewModel.set 'myNonValidatable', 'A value'
            viewModel.set 'myCommand', command
            
            # Act
            viewModel.validate()

            # Assert
            expect(validateSpy).toHaveBeenCalledOnce()

        it 'should not fail if a value that has been set is undefined', ->
            # Arrange
            command = new bo.Command 'My Command'
            validateSpy = @spy command, 'validate'

            viewModel = new bo.ViewModel
            viewModel.set 'myNonValidatable'
            viewModel.set 'myCommand', command
            
            # Act
            viewModel.validate()

            # Assert
            expect(validateSpy).toHaveBeenCalledOnce()

    describe 'When extending a ViewModel', ->
        it 'should execute the passed in constructor function on creation', ->
            # Arrange
            spy = @spy()
            viewModelType = bo.ViewModel.subclass(spy)
            
            # Act
            viewModel = new viewModelType()

            # Assert
            expect(spy).toHaveBeenCalledOnce()

        it 'should execute the constructor with "this" set to newly created object', ->
            # Arrange
            viewModelType = bo.ViewModel.subclass ->
                @aValue = 5
            
            # Act
            viewModel = new viewModelType()

            # Assert
            expect(viewModel.aValue).toBe 5

        it 'should not require a constructor function', ->
            # Arrange
            viewModelType = bo.ViewModel.subclass()
            
            # Act
            viewModel = new viewModelType()

            # Assert
            expect(viewModel).toBeDefined()

        it 'should have an isDirty property', ->
            # Arrange
            viewModelType = bo.ViewModel.subclass ->
                @aValue = 5
            
            # Act
            viewModel = new viewModelType()

            # Assert
            expect(viewModel.isDirty).toBeDefined()
