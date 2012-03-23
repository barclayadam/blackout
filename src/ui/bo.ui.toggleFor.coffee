# A binding handler that provides visibility toggling of a panel, providing
# the common UI functionality of a simple 'slide' panel, such that clicking
# a header will show and hide the content beneath that header.
ko.bindingHandlers.toggleFor =
	init: (element, valueAccessor) ->
		selector = ko.utils.unwrapObservable valueAccessor()
		$element = jQuery element
		$content = jQuery selector

		if $content.length > 0
			$element.addClass 'panel-toggle'

			updateState = ->
				$element.toggleClass 'content-expanded', $content.is ":visible"		
				$content.attr "aria-hidden", (not $content.is ":visible").toString()

			updateState()

			$element.click ->
				$content.toggle()
				updateState()
		else
			console.log "toggleFor: Could not find element from selector '#{selector}'."