describe 'Notifications', ->
    describe 'when publishing', ->
        describe 'a success notification', ->
            beforeEach ->
                bo.notifications.success 'Something good happened'

            it 'should publish a notification:success message', ->
                expect('notification:success').toHaveBeenPublishedWith 
                    text: 'Something good happened'
                    level: 'success'

        describe 'a warning notification', ->
            beforeEach ->
                bo.notifications.warning 'Something not so good happened'

            it 'should publish a notification:warning message', ->
                expect('notification:warning').toHaveBeenPublishedWith
                    text: 'Something not so good happened'
                    level: 'warning'

        describe 'an error notification', ->
            beforeEach ->
                bo.notifications.error 'Something really bad happened'

            it 'should publish a notification:error message', ->
                expect('notification:error').toHaveBeenPublishedWith
                    text: 'Something really bad happened'
                    level: 'error'

    describe 'when binding using a notification binding handler', ->
        beforeEach ->            
            @notificationElement = @setHtmlFixture '<div data-bind="notification: true" />'

            @applyBindingsToHtmlFixture {}  

        it 'should add a notification-area class to the element', ->
            expect(@notificationElement).toHaveClass 'notification-area'

        it 'should add a role attribute of alert', ->
            expect(@notificationElement).toHaveAttr 'role', 'alert'

        it 'should be an empty node to begin', ->
            expect(@notificationElement).toBeEmpty

        it 'should not be visible to begin', ->
            expect(@notificationElement).toBeHidden()

        describe 'when a success notification is published', ->
            beforeEach ->
                bo.notifications.success 'Something good happened'

            it 'should add a success class', ->
                expect(@notificationElement).toHaveClass 'success'

            it 'should set the text of the notification area to the text of the notification', ->
                expect(@notificationElement).toHaveText 'Something good happened'

            it 'should make the element visible', ->
                expect(@notificationElement).toBeVisible()

