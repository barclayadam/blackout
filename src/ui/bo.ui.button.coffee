ko.bindingHandlers.button = 
    init: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()
        $element = jQuery element

        jQuery("<span></span>")
            .html($element.text())
            .appendTo($element.empty())

        value.event = 'click'
        ko.bindingHandlers.command.init.apply @, arguments

    update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        options = valueAccessor()
        shouldExecute = ko.bindingHandlers.command.shouldExecute options.enable, viewModel
        
        ko.utils.toggleDomNodeCssClass element, 'disabled', !shouldExecute
        element.disabled = if shouldExecute then '' else 'disabled'