(behavesLikeNotification = (name) ->
	describe name, ->
		beforeEach ->
			bo.notifications[name] 'This is the message'

		it 'should raise an event with text and level', ->
			expect("notification:#{name}").toHaveBeenPublishedWith
				text: 'This is the message'
				level: name
)

describe 'notifications', ->
	behavesLikeNotification 'success'
	behavesLikeNotification 'warning'
	behavesLikeNotification 'error'