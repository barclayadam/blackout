#reference "../../js/blackout/bo.utils.coffee"

describe 'When extending an observable to be async', ->
    it 'should execute the loader immediately', ->
        # Arrange
        observable = ko.observable(456)
        loaderSpy = @spy()
        
        # Act    
        observable = observable.extend
            async: loaderSpy

        # Assert
        expect(loaderSpy).toHaveBeenCalled()

    it 'should sets the value of the observable to the value passed to the callback of the loader', ->
        # Arrange
        observable = ko.observable(456)
        
        # Act    
        observable = observable.extend 
            async: (c) -> c(123)

        # Assert
        expect(observable()).toEqual 123

    it 'should mark the observable as loading when reading the value', ->
        # Arrange
        observable = ko.observable(456)
        wasMarkedAsIsLoading = false
        
        # Act    
        observable = observable.extend 
            async: (c) -> wasMarkedAsIsLoading = observable.isLoading()

        # Assert
        expect(wasMarkedAsIsLoading).toBe true

    it 'should mark the observable as not loading when value has been set in callback', ->
        # Arrange
        observable = ko.observable(456)
        wasMarkedAsIsLoading = false
        
        # Act    
        observable = observable.extend 
            async: (c) -> c(123)

        # Assert
        expect(observable.isLoading()).toBe false

    it 'should reload the observable when a value the loader depends on changes', ->
        # Arrange
        observableOfLoader = ko.observable(345)
        observable = ko.observable(456).extend 
            async: 
                throttle: 0
                callback: (c) -> c(observableOfLoader())

        expect(observable()).toEqual 345
        
        # Act    
        observableOfLoader 123
        
        # Assert
        runs ->
            expect(observable()).toEqual 123

    it 'should throttle the callback', ->
        # Arrange
        finalValue = 45445455
        loadedCount = 0

        observableOfLoader = ko.observable(345)
        observable = ko.observable().extend 
            async: (c) -> 
                ++loadedCount
                c(observableOfLoader())
                                    
        # Act    
        observableOfLoader 123
        observableOfLoader 456
                
        # Assert
        expect(loadedCount).toEqual 1 # Last two should not have updated

describe 'When extending an observable to be publishable', ->
    describe 'with a globally publishable observable', ->
        beforeEach ->
            @observable = ko.observable(456).extend { publishable: 'MyEvent' }

        it 'returns a value which can be read', ->
            expect(@observable()).toEqual 456

        it 'returns a value which can be written', ->                
            # Act
            @observable 123

            # Assert
            expect(@observable()).toEqual 123

        it 'publishes an event on write', ->
            #Arrange
            subscriber = @spy()
            bo.bus.subscribe 'MyEvent', subscriber
                
            # Act
            @observable 123

            # Assert
            expect(subscriber).toHaveBeenCalledOnce()
            expect(subscriber).toHaveBeenCalledWith 123

        it 'does not write value if a subscriber vetoes the change', ->
            #Arrange
            subscriber = @stub().returns false
            bo.bus.subscribe 'MyEvent', subscriber
                
            # Act
            @observable 123

            # Assert
            expect(@observable()).toEqual 456

        it 'returns the value being set during event publishing', ->
            # Arrange
            observedValueDuringPublish = undefined

            subscriber = @spy =>
                observedValueDuringPublish = @observable()
                false

            bo.bus.subscribe 'MyEvent', subscriber
                
            # Act
            @observable 123

            # Assert
            expect(observedValueDuringPublish).toEqual 123
            expect(@observable()).toEqual 456

        it 'raises two change events if vetoed to indicate value reverted', ->
            # Arrange                
            spy = @spy()
            @observable.subscribe spy
                
            subscriber = @stub().returns false
            bo.bus.subscribe 'MyEvent', subscriber
                
            # Act
            @observable 123

            # Assert
            expect(spy).toHaveBeenCalledTwice()

    describe 'with a locally publishable observable', ->
        beforeEach ->
            @bus = new bo.Bus()
            @observable = ko.observable(456).extend { publishable: { message: 'MyEvent', bus: @bus } }

        it 'returns a value which can be read', ->
            expect(@observable()).toEqual 456

        it 'returns a value which can be written', ->                
            # Act
            @observable 123

            # Assert
            expect(@observable()).toEqual 123

        it 'publishes an event on write', ->
            #Arrange
            subscriber = @spy()
            @bus.subscribe 'MyEvent', subscriber
                
            # Act
            @observable 123

            # Assert
            expect(subscriber).toHaveBeenCalledOnce()
            expect(subscriber).toHaveBeenCalledWith 123

        it 'does not write value if a subscriber vetoes the change', ->
            #Arrange
            subscriber = @stub().returns false
            @bus.subscribe 'MyEvent', subscriber
                
            # Act
            @observable 123

            # Assert
            expect(@observable()).toEqual 456

        it 'returns the value being set during event publishing', ->
            # Arrange
            observedValueDuringPublish = undefined

            subscriber = @spy =>
                observedValueDuringPublish = @observable()
                false

            @bus.subscribe 'MyEvent', subscriber
                
            # Act
            @observable 123

            # Assert
            expect(observedValueDuringPublish).toEqual 123
            expect(@observable()).toEqual 456

        it 'raises two change events if vetoed to indicate value reverted', ->
            # Arrange                
            spy = @spy()
            @observable.subscribe spy
                
            subscriber = @stub().returns false
            @bus.subscribe 'MyEvent', subscriber
                
            # Act
            @observable 123

            # Assert
            expect(spy).toHaveBeenCalledTwice()

describe 'When extending an observable to be onDemand', ->
    it 'returns a value which can be read, with the default value being returned initially', ->
        # Act
        observable = ko.observable("A Value").extend { onDemand: -> }
            
        # Assert
        expect(observable()).toEqual "A Value"

    it 'returns a value which can be written', ->
        #Arrange
        observable = ko.observable(456).extend { onDemand: -> }
            
        # Act
        observable 123

        # Assert
        expect(observable()).toEqual 123

    it 'sets loaded property to true if a value is written directly', ->
        #Arrange
        observable = ko.observable(456).extend { onDemand: -> }
            
        # Act
        observable 123

        # Assert
        expect(observable.loaded()).toEqual true

    it 'has a loaded observable that is initially set to false', ->            
        # Act
        observable = ko.observable(456).extend { onDemand: -> }

        # Assert
        expect(observable.loaded).toBeObservable()
        expect(observable.loaded()).toBe false

    it 'has a loaded observable that is set to true when value is set', ->            
        # Arrange
        observable = ko.observable(456).extend { onDemand: -> }

        # Act
        observable 123

        # Assert
        expect(observable.loaded()).toBe true

    it 'has a isLoading observable that is initially set to false', ->            
        # Act
        observable = ko.observable(456).extend { onDemand: -> }

        # Assert
        expect(observable.isLoading).toBeObservable()
        expect(observable.loaded()).toBe false

    it 'calls the loader callback when load method is called, with observable as parameter', ->     
        # Arrange
        callbackSpy = @spy()
        observable = ko.observable(456).extend { onDemand: callbackSpy }

        # Act
        observable.load()

        # Assert
        expect(callbackSpy).toHaveBeenCalledOnce()
        expect(callbackSpy).toHaveBeenCalledWith observable

    it 'does not calls the loader callback if value has already been loaded', ->     
        # Arrange
        callbackSpy = @spy()
        observable = ko.observable(456).extend { onDemand: callbackSpy }
        observable 123

        # Act
        expect(observable.loaded()).toBe true
        observable.load()

        # Assert
        expect(callbackSpy.called).toBe false

    it 'calls the callback parameter when load method is called and loader has set value', ->     
        # Arrange
        callbackSpy = @spy()
        observable = ko.observable(456).extend { onDemand: (o) -> o(123) }

        # Act
        observable.load callbackSpy

        # Assert
        expect(callbackSpy).toHaveBeenCalledOnce()

    it 'sets isLoading to true on load', ->     
        # Arrange
        observable = ko.observable(456)

        isLoadingValueOnCallback = null
        callbackSpy = @spy ->
            isLoadingValueOnCallback = observable.isLoading()

        # Act
        observable = observable.extend { onDemand: callbackSpy }
        observable.load()

        # Assert
        expect(isLoadingValueOnCallback).toBe true

    it 'sets loaded to false on refresh', ->     
        # Arrange
        observable = ko.observable(456).extend { onDemand: -> }

        # Make sure loaded set to true, to watch it change back
        observable(123)
        
        # Act
        # loaded will not be set to true as callback does not set the value
        observable.refresh()

        # Assert
        expect(observable.loaded()).toBe false

    it 'has array methods if extending an observableArray', ->     
        # Act
        observable = ko.observableArray([]).extend { onDemand: -> }

        # Assert
        # TODO: Is there a better way of checking for all array methods?
        expect(observable.remove).toBeAFunction()
        expect(observable.push).toBeAFunction()
        expect(observable.pop).toBeAFunction()
