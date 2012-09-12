((window, document, $, ko) ->	
	if ko is undefined
	    throw new Error 'knockout must be included before boson'

    # Declare some common variables used throughout the library
    # to help reduce minified size.
    koBindingHandlers = ko.bindingHandlers

	# Root namespace into which the public API will be exported.
	bo = window.bo = {}

	###import "bo.log.coffee" ###
	###import "bo.utils.coffee" ###
	###import "bo.bus.coffee" ###
	###import "bo.uri.coffee" ###
	###import "bo.ajax.coffee" ###
	###import "bo.storage.coffee" ###
	###import "bo.notifications.coffee" ###
	###import "bo.templating.coffee" ###
	###import "bo.validation.coffee" ###
	###import "bo.validation.rules.coffee" ###
	###import "bo.dataSource.coffee" ###
	###import "bo.location.coffee" ###
	###import "bo.routing.coffee" ###
	
	###import "bo.tagBindingsProvider.coffee" ###

	###import "bo.viewModel.coffee" ###

	###import "bo.ui.partBindingHandler.coffee" ###
	###import "bo.ui.regionManager.coffee" ###
)(window, document, window["jQuery"], window["ko"])