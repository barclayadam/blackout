# A utility binding handler that will typically be used within the 
# implementation of 'widgets' that have multiple children items that
# should not individually participate in the tabbing ordering of the
# page.
#
# The value accessor should be an observable that indicates whether the
# element is the currently focused child (e.g. a tree item being the
# focused element). When the value changes to `true` the `tabIndex` of
# the element is set to `0` and the element is focused (e.g. `element.focus()`),
# else `tabIndex` is set to `-1`.
ko.bindingHandlers.tabIndex =
    update: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()
        previousValue = element.tabIndex is 0

        if not element.tabIndexAdded or value is not previousValue            
            element.tabIndexAdded = true

            if value is true
                element.tabIndex = "0"
                element.focus()
            else 
                element.tabIndex = "-1"