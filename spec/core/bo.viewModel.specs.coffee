describe 'view model', ->
    describe 'subclassing viewModel', ->
        beforeEach ->
            @viewModel = bo.ViewModel.extend
                nonObservable: 'My Non Observable Value'
                
                performSomeAction: @spy()

            @viewModelInstance = new @viewModel()

        it 'should set directly defined properties as properties of the view models prototype', ->
            expect(@viewModelInstance.nonObservable).toEqual 'My Non Observable Value'            
            expect(@viewModel.prototype.nonObservable).toEqual 'My Non Observable Value'