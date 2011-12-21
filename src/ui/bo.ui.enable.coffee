# Make the built-in enable (and therefore disable) binding handlers slightly more
# useful by applying a 'disabled' class when element is disabled, allowing
# better targeting via CSS, particularly for non-form elements such as links.
currentEnableBindingUpdate = ko.bindingHandlers.enable.update

ko.bindingHandlers.enable.update = (element, valueAccessor) ->
    currentEnableBindingUpdate element, valueAccessor

    ko.utils.toggleDomNodeCssClass element, 'disabled', !ko.utils.unwrapObservable valueAccessor()