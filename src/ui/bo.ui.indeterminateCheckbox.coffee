# reference "../lib/jquery.js"
# reference "../lib/jquery.ui.js"
# reference "../lib/knockout.js"
# reference "bo.coffee"

ko.bindingHandlers.indeterminateCheckbox = 
    init: (element, valueAccessor) ->
        $element = jQuery element

        $element.click ->
            if (ko.utils.unwrapObservable valueAccessor()) is "mixed"
                valueAccessor() true
            else
                valueAccessor() $element.is ":checked"

    update: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()
        originalInput = jQuery element

        if value is "mixed"
            originalInput.prop "indeterminate", true
        else
            originalInput.prop "indeterminate", false
            originalInput.prop "checked", value
