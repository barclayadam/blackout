describe 'part binding handler', ->
    describe 'binding undefined view model', ->
        beforeEach ->           
            @setHtmlFixture """
                <div id="fixture" data-bind="part: viewModel">
                    This is an anonymous template
                </div>
            """

            @applyBindingsToFixture 
                viewModel: undefined

            @wrapper = document.getElementById "fixture"

        it 'should not render the template', ->
            expect(@wrapper).toBeEmpty()

    describe 'binding a plain object with anonymous template', ->
        beforeEach ->           
            @viewModel =
                aProperty: 'A Property'

                anObservableProperty: ko.observable 'An observable property'

            ko.bindingHandlers.test1 =
                init: @spy()

                update: @spy (element, valueAccessor) ->
                    ko.utils.unwrapObservable valueAccessor() # Ensure a subscription exists
                    
            @setHtmlFixture """
                <div id="fixture" data-bind="part: viewModel">
                    This is an anonymous template

                    <span data-bind="test1: anObservableProperty"></span>
                </div>
            """

            @applyBindingsToFixture 
                viewModel: @viewModel

            @wrapper = document.getElementById "fixture"

            @viewModel.anObservableProperty 'A New Value'

        it 'should set view model as context when rendering template', ->
            # Just check that when binding directly to a property of the view model 
            # binding handlers are getting called with it (a little brittle!)
            expect(ko.bindingHandlers.test1.init.args[0][1]()).toBe @viewModel.anObservableProperty

        it 'should not re-render the whole view when a property of the view model changes', ->
            # Init for first rendering, update for first rendering an update of
            # property.
            expect(ko.bindingHandlers.test1.init).toHaveBeenCalledOnce()
            expect(ko.bindingHandlers.test1.update).toHaveBeenCalledTwice()

    describe 'binding a plain object with named view', ->
        beforeEach ->           
            bo.templating.set 'myNamedPartTemplate', 'This is the template'

            @viewModel =
                templateName: 'myNamedPartTemplate'

            @setHtmlFixture """
                <div id="fixture" data-bind="part: viewModel"></div>
            """

            @applyBindingsToFixture 
                viewModel: @viewModel

            @wrapper = document.getElementById "fixture"

        it 'should use the named template', ->
            # Just check that when binding directly to a property of the view model 
            # binding handlers are getting called with it (a little brittle!)
            expect(@wrapper).toHaveText 'This is the template'

    describe 'lifecycle', ->
        describe 'without AJAX requests', ->
            beforeEach ->   
                @showHadContent = undefined
                @afterShowHadContent = undefined

                @viewModel =
                    anObservableProperty: ko.observable()

                    show: @spy =>
                        @showHadContent = document.getElementById("fixture").innerText.length > 0

                    afterShow: @spy =>
                        @afterShowHadContent = document.getElementById("fixture").innerText.length > 0

                @setHtmlFixture """
                    <div id="fixture" data-bind="part: viewModel">
                        This is the template
                    </div>
                """

                @applyBindingsToFixture 
                    viewModel: @viewModel 

            it 'should call show function before afterShow', ->
                expect(@viewModel.show).toHaveBeenCalledBefore @viewModel.afterShow

            it 'should call show function before rendering', ->
                expect(@showHadContent).toEqual false

            it 'should call afterShow function before rendering', ->
                expect(@afterShowHadContent).toEqual true

        describe 'with AJAX requests in show', ->
            beforeEach ->   
                @viewModel =
                    anObservableProperty: ko.observable()

                    show: @spy ->
                        bo.ajax.url('/Users/Managers').get()

                    afterShow: @spy =>
                        @afterShowHadContent = document.getElementById("fixture").innerText.length > 0

                    hide: @spy()

                @setHtmlFixture """
                    <div id="fixture" data-bind="part: viewModel">
                        This is the template
                    </div>
                """

                @applyBindingsToFixture 
                    viewModel: @viewModel 

            it 'should not render template before ajax requests complete', ->
                # We have not responded from server yet
                expect(document.getElementById("fixture")).toBeEmpty()

            it 'should not call afterShow before ajax requests complete', ->
                # We have not responded from server yet
                expect(@viewModel.afterShow).toHaveNotBeenCalled()

            describe 'after AJAX requests complete', ->
                beforeEach ->  
                    @server.respondWith 'GET', '/Users/Managers', [200, { "Content-Type": "text/html" }, 'A Response']
                    @server.respond() 

                it 'should render template', ->
                    # We have now responded from server
                    expect(document.getElementById("fixture")).not.toBeEmpty()

                it 'should call afterShow before ajax requests complete', ->
                    # We have now responded from server
                    expect(@viewModel.afterShow).toHaveBeenCalled()

        describe 'switching view models', ->
            beforeEach ->   
                bo.templating.set 'viewModelOneTemplate', 'Template One'
                bo.templating.set 'viewModelTwoTemplate', 'Template Two'

                @viewModelOne =
                    templateName: 'viewModelOneTemplate'

                    beforeShow: @spy()
                    show: @spy()
                    hide: @spy()

                @viewModelTwo =
                    templateName: 'viewModelTwoTemplate'

                    beforeShow: @spy()
                    show: @spy()
                    hide: @spy()

                @viewModel = ko.observable @viewModelOne

                @setHtmlFixture """
                    <div id="fixture" data-bind="part: viewModel">
                        This is the template
                    </div>
                """

                @applyBindingsToFixture 
                    viewModel: @viewModel 

                @wrapper = document.getElementById "fixture" 

                # Perform the switch of view models by updating the bound
                # observable.
                @viewModel @viewModelTwo

            it 'should call hide of existing view model before showing new one', ->
                expect(@viewModelOne.hide).toHaveBeenCalledBefore @viewModelTwo.beforeShow
                expect(@viewModelOne.hide).toHaveBeenCalledBefore @viewModelTwo.show

            it 'should not call hide of new view model', ->
                expect(@viewModelTwo.hide).toHaveNotBeenCalled()

            it 'should switch the templates (when not anonymous)', ->
                expect(@wrapper).toHaveText 'Template Two'

