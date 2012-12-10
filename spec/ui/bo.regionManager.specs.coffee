describe 'region manager', ->
    describe 'region without a region manager', ->
        beforeEach ->
            # Typically, a region manager would be the root `app` on the
            # body, but it is not a requirement.
            @setHtmlFixture """
                <div id="body">
                    <region class="region"></region>
                </div>
            """

            @applyBindingsFunc = =>
                @applyBindingsToHtmlFixture()

        it 'should throw an exception detailing incorrect usage', ->
            expect(@applyBindingsFunc).toThrow 'A region binding handler / tag must be a child of a regionManager'

    describe 'single region', ->
        beforeEach ->
            @regionManager = new bo.RegionManager()

            # Typically, a region manager would be the root `app` on the
            # body, but it is not a requirement.
            @setHtmlFixture """
                <div id="body" data-bind="regionManager: regionManager">
                    <header>This is the header</header>

                    <region id="my-main-region" class="region"></region>

                    <footer>This is the footer</footer>
                </div>
            """

            @applyBindingsToHtmlFixture 
                regionManager: @regionManager

            @wrapper = @fixture.find("div")

        it 'should not affect any contents of element that is not a region', ->
            expect(@wrapper.find("header")).toHaveText "This is the header"
            expect(@wrapper.find("footer")).toHaveText "This is the footer"

        it 'should replace region with a div tag', ->
            expect(@wrapper.find("div.region")).toExist()

        it 'should place no content in region if no view model has been set ', ->
            expect(@wrapper.find("div.region")).toBeEmpty()

        describe 'with view model set', ->
            beforeEach ->
                @partBindingHandlerSpy = @spy ko.bindingHandlers.part, "update"

                bo.templating.set 'myViewModelTemplateName', 'This is the template'

                @viewModel =
                    templateName: 'myViewModelTemplateName'

                @regionManager.showSingle @viewModel

            it 'should render the view model and its associated template in single region', ->
                expect(@wrapper.find("div.region")).toHaveText 'This is the template'

            it 'should use part binding handler to handle rendering', ->
                expect(@partBindingHandlerSpy).toHaveBeenCalled()

    describe 'multiple regions with a default set', ->
        beforeEach ->
            @regionManager = new bo.RegionManager()

            # Typically, a region manager would be the root `app` on the
            # body, but it is not a requirement.
            @setHtmlFixture """
                <div id="body" data-bind="regionManager: regionManager">
                    <header>This is the header</header>

                    <region id="main" data-default="true"></region>
                    <region id="help"></region>

                    <footer>This is the footer</footer>
                </div>
            """

            @applyBindingsToHtmlFixture 
                regionManager: @regionManager

            @wrapper = @fixture.find("div")

        it 'should not affect any contents of element that is not a region', ->
            expect(@wrapper.find("header")).toHaveText "This is the header"
            expect(@wrapper.find("footer")).toHaveText "This is the footer"

        it 'should replace all regions with div tags', ->
            expect(@wrapper.find("div#main")).toExist()
            expect(@wrapper.find("div#help")).toExist()

        it 'should place no content in regions if no view model has been set ', ->
            expect(@wrapper.find("div#main")).toBeEmpty()
            expect(@wrapper.find("div#help")).toBeEmpty()

        describe 'show', ->
            beforeEach ->
                bo.templating.set 'myViewModelTemplateName', 'This is the main template'

                @viewModel =
                    templateName: 'myViewModelTemplateName'

                @regionManager.showSingle @viewModel

            it 'should set the view model to the default region', ->
                expect(@wrapper.find("div#main")).toHaveText 'This is the main template'

        describe 'show', ->
            describe 'with one view model set', ->
                beforeEach ->
                    bo.templating.set 'myViewModelTemplateName', 'This is the main template'

                    @mainViewModel =
                        templateName: 'myViewModelTemplateName'

                    @regionManager.show 
                        'main': @mainViewModel

                it 'should render the view model and its associated template in set region', ->
                    expect(@wrapper.find("div#main")).toHaveText 'This is the main template'

                it 'should leave the unset region blank', ->
                    expect(@wrapper.find("div#help")).toBeEmpty()

            describe 'with all view models set', ->
                beforeEach ->
                    bo.templating.set 'myMainViewModelTemplateName', 'This is the main template'
                    bo.templating.set 'myHelpViewModelTemplateName', 'This is the help template'

                    @mainViewModel =
                        templateName: 'myMainViewModelTemplateName'

                    @helpViewModel =
                        templateName: 'myHelpViewModelTemplateName'

                    @regionManager.show 
                        'main': @mainViewModel
                        'help': @helpViewModel

                it 'should render the view models and associated templates', ->
                    expect(@wrapper.find("div#main")).toHaveText 'This is the main template'
                    expect(@wrapper.find("div#help")).toHaveText 'This is the help template'

                describe 'show called again with only a single region', ->
                    beforeEach ->
                        bo.templating.set 'myNewMainViewModelTemplateName', 'This is the new main template'

                        @newMainViewModel =
                            templateName: 'myNewMainViewModelTemplateName'
                        
                        @regionManager.show 
                            'main': @newMainViewModel

                    it 'should re-render the changed region', ->    
                        expect(@wrapper.find("div#main")).toHaveText 'This is the new main template'

                    it 'should not change the region not passed in', ->    
                        expect(@wrapper.find("div#help")).toHaveText 'This is the help template'

            describe 'with unknown region specified in show', ->
                beforeEach ->
                    bo.log.debug = @spy()

                    @regionManager.show 
                        'main': {}
                        'unknown': {}

                it 'should log a debug error message', ->
                    expect(bo.log.debug).toHaveBeenCalledWith "This region manager does not have a 'unknown' region"
