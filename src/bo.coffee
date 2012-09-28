((window, document, $, ko) ->	
	if ko is undefined
	    throw new Error 'knockout must be included before blackout.'

    # Declare some common variables used throughout the library
    # to help reduce minified size.
    koBindingHandlers = ko.bindingHandlers

	# Root namespace into which the public API will be exported.
	bo = window.bo = {}

	#= core/bo.log.coffee

	#= core/bo.utils.coffee
	#= core/bo.bus.coffee
	#= core/bo.uri.coffee
	#= core/bo.ajax.coffee
	#= core/bo.storage.coffee
	#= core/bo.notifications.coffee
	#= core/bo.templating.coffee
	#= core/bo.validation.coffee
	#= core/bo.validation.rules.coffee
	#= core/bo.dataSource.coffee
	#= core/bo.location.coffee
	#= core/bo.routing.coffee
	
	#= core/bo.tagBindingsProvider.coffee

	#= core/bo.viewModel.coffee

	#= ui/bo.ui.partBindingHandler.coffee
	#= ui/bo.ui.regionManager.coffee
)(window, document, window["jQuery"], window["ko"])