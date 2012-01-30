describe 'Dialog', ->
    describe 'when dialog shown with a single part', ->
        beforeEach ->
            @parameters = { aProperty: 'my value' }

            @showSpy = @spy()
            @viewModel = 
                myProperty: ko.observable ('A Value')

                getDialogOptions: ->
                    title: 'My title'
                
                show: @showSpy
            @part = new bo.Part 'My Fancy Dialog', { templateName: 'myFancyDialogTemplate', viewModel: @viewModel}
            @dialog = new bo.Dialog @part

            @setHtmlFixture '''
                <script id="myFancyDialogTemplate" type="text/x-tmpl">
                    <h1 id="my-dialog-property" data-bind="text: myProperty"></h1>
                </script>               
            '''

            # Act
            @dialog.show @parameters

        it 'should call the show method of the view model', ->
            expect(@showSpy).toHaveBeenCalled()

        it 'should pass the parameters to show to the show method of the view model', ->
            expect(@showSpy).toHaveBeenCalledWith @parameters

        it 'should show the dialog on-screen', ->
            # This test is a little brittle, just checking dialog contents have been shown
            # somewhere visible on screen
            expect(jQuery("#my-dialog-property")).toBeVisible()

        it 'should bind the dialog contents to the view model', ->
            # This test is a little brittle, just checking dialog contents have been shown
            # somewhere visible on screen
            expect(jQuery("#my-dialog-property")).toHaveText 'A Value'

        it 'should use the title from the getDialogOptions function of the view model as the title of the dialog', ->
            # This test is a little brittle, relying on some specifics of
            # jQuery UI's output.
            expect(jQuery(".ui-dialog-title")).toHaveText 'My title'