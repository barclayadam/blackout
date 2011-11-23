# reference "../lib/knockout.js"
# reference "bo.coffee"

window.bo.utils =
    addTemplate: (name, template) ->
        if jQuery("##{name}").length is 0
            document.write "<script type='text/x-jquery-tmpl' id='#{name}'>#{template}</script>"

    fromCamelToTitleCase: (str) ->
        str
            .replace(/([a-z])([A-Z])/g, '$1 $2') # insert a space between lower & upper
            .replace(/\b([A-Z]+)([A-Z])([a-z])/, '$1 $2$3') # space before last upper in a sequence followed by lower
            .replace(/^./, (s) -> s.toUpperCase()) # uppercase the first character

    asObservable: (value) ->
        if _.isArray value then ko.observableArray value else ko.observable value

    toCssClass: (value) ->
        value = ko.utils.unwrapObservable value

        value.replace(' ', '-').toLowerCase() if value?

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