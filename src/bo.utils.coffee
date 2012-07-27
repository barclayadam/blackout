# reference "../lib/knockout.js"
# reference "bo.coffee"

window.bo.utils =
    addTemplate: (name, template) ->
        if jQuery("##{name}").length is 0
            jQuery('head').append "<script type='text/x-knockout-tmpl' id='#{name}'>#{template}</script>"

    fromCamelToTitleCase: (str) ->
        str.toString()
            .replace(/([a-z])([A-Z])/g, '$1 $2') # insert a space between lower & upper
            .replace(/\b([A-Z]+)([A-Z])([a-z])/, '$1 $2$3') # space before last upper in a sequence followed by lower
            .replace(/^./, (s) -> s.toUpperCase()) # uppercase the first character

    asObservable: (value) ->
        if ko.isObservable value then return value
        if _.isArray value then ko.observableArray value else ko.observable value

    toCssClass: (value) ->
        value = (ko.utils.unwrapObservable value)

        if value
            value = bo.utils.fromCamelToTitleCase value 
            value = value.replace /[ /\\]/g, '-'
            value = value.toLowerCase()
            value

    joinObservables: (masterObservable, others...) ->
        other masterObservable() for other in others

        propagating = false

        masterObservable.subscribe (newValue) ->
            if !propagating
                propagating = true

                for o in others
                    o newValue
            
                propagating = false

        for o in others
            o.subscribe (newValue) ->
                masterObservable newValue

    # Creates a new resolved promise, useful when either returning or passing
    # arguments that should be a promise for clients but no work is required, therefore
    # a resolved promise should be used.
    resolvedPromise: () ->
        deferred = new jQuery.Deferred()
        deferred.resolve()
        deferred

    failedPromise: () ->
        deferred = new jQuery.Deferred()
        deferred.reject()
        deferred

    # Given the 'allBindingsAccessor' parameter of a binding handler will
    # determine whether or not the element is enabled, based on both the enabled
    # and disabled binding handlers that exist.
    isElementEnabled: (allBindingsAccessor) ->        
        enabledBinding = allBindingsAccessor().enabled
        disabledBinding = allBindingsAccessor().disabled

        ko.utils.unwrapObservable (enabledBinding ? true) and
            !ko.utils.unwrapObservable (disabledBinding ? false)