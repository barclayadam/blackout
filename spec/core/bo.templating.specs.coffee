describe 'templating', ->        
    # Ensure existing functionality left in-tact
    describe 'when using built-in template binding handler with anonymous template', ->
        beforeEach ->
            @setHtmlFixture """
                <div data-bind="template: {}">My Anonymous Template Text</div>
            """

            @applyBindingsToHtmlFixture {}  
            @wrapper = @fixture.find("div")  

        it 'should render the anonymous template', ->
            expect(@wrapper).toHaveText 'My Anonymous Template Text'  

    describe 'string templates', ->
        describe 'when a named template is added', ->
            beforeEach ->
                bo.templating.set 'myNamedTemplate', 'A Cool Template'

                @setHtmlFixture """
                    <div data-bind="template: 'myNamedTemplate'"></div>
                """

                @applyBindingsToHtmlFixture {}  
                @wrapper = @fixture.find("div")  

            it 'should render template', ->
                expect(@wrapper).toHaveText 'A Cool Template'   

        describe 'when a named template is set twice', ->
            beforeEach ->
                bo.templating.set 'myNamedTemplate', 'A Cool Template'
                bo.templating.set 'myNamedTemplate', 'A Cool Template 2'

                @setHtmlFixture """
                    <div data-bind="template: 'myNamedTemplate'"></div>
                """

                @applyBindingsToHtmlFixture {}  
                @wrapper = @fixture.find("div")  

            it 'should render the last template added', ->
                expect(@wrapper).toHaveText 'A Cool Template 2'      

        describe 'when a named template is an observable', ->
            beforeEach ->
                @template = ko.observable 'A Cool Template'
                bo.templating.set 'myNamedTemplate', @template
                
                @setHtmlFixture """
                    <div data-bind="template: 'myNamedTemplate'"></div>
                """

                @applyBindingsToHtmlFixture {}  
                @wrapper = @fixture.find("div")  

            it 'should render the template', ->
                expect(@wrapper).toHaveText @template()

            describe 'that is updated', ->
                beforeEach ->
                    @template 'Some other cool template'

                it 'should re-render the template', ->
                    expect(@wrapper).toHaveText 'Some other cool template'  

            describe 'that is set again', ->
                beforeEach ->
                    bo.templating.set 'myNamedTemplate', 'Explicitly set template again'

                it 'should re-render the template', ->
                    expect(@wrapper).toHaveText 'Explicitly set template again'  

    describe 'external templates', ->
        describe 'when an external template name is used by specifying e: prefix', ->
            beforeEach ->
                @template = "A cool template"

                # Use {name} to specify injection point for template name
                bo.templating.externalPath = '/Get/Template/{name}'
                @respondWithTemplate '/Get/Template/myExternalTemplate', @template     

                @setHtmlFixture """
                    <div id='one' data-bind="template: 'e:myExternalTemplate'"></div>
                    <div id='two' data-bind="template: 'e:myExternalTemplate'"></div>
                """

                @ajaxSpy = @spy $, 'ajax'

                @applyBindingsToHtmlFixture {}  
                @wrapperOne = @fixture.find "#one"
                @wrapperTwo = @fixture.find "#two"

            it 'should immediately render the loading template (bo.templating.loadingTemplate)', ->
                expect(@wrapperOne).toHaveText bo.templating.loadingTemplate
                expect(@wrapperTwo).toHaveText bo.templating.loadingTemplate

            it 'should only attempt one load of the document from the server', ->
                expect(@ajaxSpy).toHaveBeenCalledOnce()

            describe 'when template is successfully loaded using bo.templating.externalPath', ->
                beforeEach -> 
                    @server.respond()

                it 'should render template', ->
                    expect(@wrapperOne).toHaveText @template
                    expect(@wrapperTwo).toHaveText @template