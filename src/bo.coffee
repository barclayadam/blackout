((window, document, $, ko) ->	
	((factory) ->
		# Support three module loading scenarios
		if typeof require is "function" and typeof exports is "object" and typeof module is "object"		  
		    # [1] CommonJS/Node.js
		    factory module["exports"] or exports # module.exports is for Node.js
		else if typeof define is "function" and define["amd"]		  
		    # [2] AMD anonymous module
		    define ["exports"], factory
		else		  
		    # [3] No module loader (plain <script> tag) - put directly in global namespace
		    factory window["bo"] = {}
	)((boExports) ->
		if ko is undefined
		    throw new Error 'knockout must be included before blackout.'

	    # Declare some common variables used throughout the library
	    # to help reduce minified size.
	    koBindingHandlers = ko.bindingHandlers

		# Root namespace into which the public API will be exported.
		bo = boExports ? {}
        
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
	)

)(window, document, window["jQuery"], window["ko"])