describe 'component binding provider', ->
    # A small selection of tests for existing functionality as a sanity check. NOT comprehensive.
    describe 'existing functionality', ->
        beforeEach ->           
            @setHtmlFixture """
                <div id='literal' data-bind="text: 'My Text'"></div>
                <div id='multiple' data-bind="text: 'My Text', css: { myClass: true }"></div>
                <div id='non-updated' data-bind="text: myTextObservable"></div>
                <div id='updated' data-bind="text: myUpdatedTextObservable"></div>
            """

            @myTextObservable = ko.observable 'A Value'
            @myUpdatedTextObservable = ko.observable 'A Value'

            @applyBindingsToHtmlFixture 
                myTextObservable: @myTextObservable 
                myUpdatedTextObservable: @myUpdatedTextObservable

            @wrapper = @fixture.find("div") 

            @myUpdatedTextObservable 'A New Value'

        it 'should apply bindings with literal values', ->
            expect(@fixture.find('#literal')).toHaveText 'My Text'

        it 'should apply multiple bindings with literal values', ->
            expect(@fixture.find('#multiple')).toHaveText 'My Text'
            expect(@fixture.find('#multiple')).toHaveClass 'myClass'

        it 'should apply bindings with observable values', ->
            expect(@fixture.find('#non-updated')).toHaveText @myTextObservable()

        it 'should apply bindings with observable values for updates', ->
            expect(@fixture.find('#updated')).toHaveText @myUpdatedTextObservable()

    describe 'binding handler not specified as tag compatible', ->
        beforeEach ->           
            @setHtmlFixture """
                <div data-option="'My Text'">Existing Value</div>
            """

            @applyBindingsToHtmlFixture {}

        it 'should not use binding handler', ->
            expect(@fixture.find("div")).toHaveText 'Existing Value'

    describe 'binding handler specified as tag compatible, with replacement', ->
        beforeEach ->   
            @valuePassed = undefined
            @complexValuePassed = undefined

            ko.bindingHandlers.tagSample =
                tag: 'tagSample->div'

                init: (element, valueAccessor) =>
                    ko.utils.setTextContent element, 'My New Text'

                    @valuePassed = valueAccessor()

                update: (element) ->
                    ko.utils.toggleDomNodeCssClass element, 'myClass', true

            ko.bindingHandlers.complexOptionSample =
                tag: 'complexOptionSample->span'

                init: (element, valueAccessor) =>
                    @complexValuePassed = valueAccessor()

            ko.bindingHandlers.templateTag =
                tag: 'templateTag->div'

                init: (element, valueAccessor) ->
                    bo.templating.set 'myNamedTemplate', 'A Cool Template'
                    ko.renderTemplate "myNamedTemplate", {}, {}, element, "replaceChildren"

            @setHtmlFixture """
                <div>
                    <tagSample id="tag-sample" data-option="'My Passed In Value'" data-bind="css: { myOtherBoundClass: true }"></tagSample>
                    <complexOptionSample id="complex-option-sample" data-option="{ key: 'complex value' }"></complexOptionSample>
                    <templateTag id="template-tag" class="my-class"></templateTag>
                </div>
            """

            debugger
            @applyBindingsToHtmlFixture {}

        it 'should call binding handlers init function, and allow text content of nodes to be set', ->
            expect(@fixture.find("#tag-sample")).toHaveText 'My New Text'

        it 'should call binding handlers update function', ->
            expect(@fixture.find("#tag-sample")).toHaveClass 'myClass'

        it 'should replace node using tag name specified in binding handler', ->
            expect(@fixture.find("#tag-sample")[0].tagName.toLowerCase()).toEqual 'div'
            expect(@fixture.find("#complex-option-sample")[0].tagName.toLowerCase()).toEqual 'span'
            expect(@fixture.find("#template-tag")[0].tagName.toLowerCase()).toEqual 'div'

        it 'should work with templating', ->
            expect(@fixture.find("#template-tag")).toHaveText 'A Cool Template'

        it 'should maintain existing attributes', ->
            expect(@fixture.find("#template-tag")).toHaveAttr 'class', 'my-class'

        it 'should use data-bind attribute as well', ->
            expect(@fixture.find("#tag-sample")).toHaveClass 'myOtherBoundClass'

        it 'should pass simple type data-option to init', ->
            expect(@valuePassed).toEqual 'My Passed In Value'

        it 'should pass complex type data-option to init', ->
            expect(@complexValuePassed).toEqual { key: 'complex value' }

    describe 'binding handler specified as tag compatible, without replacement', ->
        beforeEach ->   
            ko.bindingHandlers.inputEnhancer =
                tag: 'input'

                init: (element, valueAccessor) =>
                    ko.utils.toggleDomNodeCssClass element, 'a-new-class', true

            @setHtmlFixture """
                <div>
                    <input id="input-control" />
                </div>
            """

            @applyBindingsToHtmlFixture {}

        it 'should call binding handlers init function', ->
            expect(@fixture.find("#input-control")).toHaveClass 'a-new-class'

        it 'should not replace the element with another', ->
            expect(@fixture.find("#input-control")[0].tagName).toEqual 'INPUT'

    describe 'multiple binding handlers specified as tag compatible, without replacement', ->
        beforeEach ->   
            ko.bindingHandlers.exampleEnhancer1 =
                tag: 'example'

                init: (element, valueAccessor) =>
                    ko.utils.toggleDomNodeCssClass element, 'a-new-class', true

            ko.bindingHandlers.exampleEnhancer2 =
                tag: 'example'

                init: (element, valueAccessor) =>
                    ko.utils.toggleDomNodeCssClass element, 'another-new-class', true

            @setHtmlFixture """
                <div>
                    <example id="example-control" />
                </div>
            """

            @applyBindingsToHtmlFixture {}

        it 'should call all binding handlers init function', ->
            expect(@fixture.find("#example-control")).toHaveClass 'a-new-class'
            expect(@fixture.find("#example-control")).toHaveClass 'another-new-class'

        it 'should not replace the element with another', ->
            expect(@fixture.find("#example-control")[0].tagName).toEqual 'EXAMPLE'