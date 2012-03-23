specForVisibleContent = ->
    it 'should add a content-expanded class to the header', ->
        expect(@header).toHaveClass 'content-expanded'

    it 'should add aria-hidden attribute of the content to false', ->
        expect(@content).toHaveAttr 'aria-hidden', 'false'

specForHiddenContent = ->
    it 'should not add a content-expanded class to the header', ->
        expect(@header).toNotHaveClass 'content-expanded'

    it 'should add aria-hidden attribute of the content to false', ->
        expect(@content).toHaveAttr 'aria-hidden', 'true'

describe 'toggleFor handler', ->
    describe 'with an unmatched selector as parameter', ->
        beforeEach ->
            @setHtmlFixture """
                <header data-bind="toggleFor: '#unknownSelector'">
                </header>
            """

            @applyBindingsToHtmlFixture {}  
            @header = @fixture.find "header"

        it 'should not add a panel-toggle class to the header', ->
            expect(@header).toNotHaveClass 'panel-toggle'

    describe 'with a matched selector and initially visible content', ->
        beforeEach ->
            @setHtmlFixture """
                <header data-bind="toggleFor: '#myToggledContent'">
                </header>

                <article id="myToggledContent">
                </article>
            """

            @header = @fixture.find "header"
            @content = @fixture.find "article"
            @applyBindingsToHtmlFixture {}

        it 'should add a panel-toggle class to the header', ->
            expect(@header).toHaveClass 'panel-toggle'

        describe 'and initially visible content', ->
            beforeEach ->
                @content.show()
                @applyBindingsToHtmlFixture {}

            specForVisibleContent()

            describe 'when header clicked', ->
                beforeEach ->
                    @content.show()
                    @applyBindingsToHtmlFixture {}
                    @header.click()

                specForHiddenContent()

        describe 'and initially hidden content', ->
            beforeEach ->
                @content.hide()
                @applyBindingsToHtmlFixture {}

            specForHiddenContent()

            describe 'when header clicked', ->
                beforeEach ->
                    @content.hide()
                    @applyBindingsToHtmlFixture {}
                    @header.click()

                specForVisibleContent()