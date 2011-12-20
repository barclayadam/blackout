# reference "../lib/jquery.js"
# reference "../lib/jquery.ui.js"
# reference "../lib/knockout.js"
# reference "bo.coffee"

ko.bindingHandlers.button =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        jQuery(element).button()

        value = ko.utils.unwrapObservable valueAccessor()

        if not (value is true)		    
            value.event = 'click'

            ko.bindingHandlers.command.init.apply @, arguments

    update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        options = valueAccessor()

        if ko.bindingHandlers.command.shouldExecute options.enable, viewModel
            jQuery(element).button "enable"
        else
            jQuery(element).button "disable"

ko.bindingHandlers.datepicker =
    init: (element) ->
        jQuery(element).datepicker({ dateFormat: 'yy/mm/dd' })

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
