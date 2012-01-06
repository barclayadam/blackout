# A binding handler that should be applied to buttons to provide some
# common additions to standard HTML buttons (e.g. input[submit] and button elements)
# to allow better and more consistent styling cross-browser.
#
# The option passed can either be `true`, which provides the basic changes, or
# a function that will be called on click, with the function being passed through to
# the `ko.bindingHandlers.click` binding handler.
ko.bindingHandlers.button = 
    init: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()
        $element = jQuery element

        jQuery("<span></span>")
            .html($element.text())
            .appendTo($element.empty())

        if _.isFunction value
            ko.bindingHandlers.click.init.apply @, arguments