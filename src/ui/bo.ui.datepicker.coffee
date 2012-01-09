# reference "bo.coffee"

ko.bindingHandlers.datepicker =
    init: (element) ->
        jQuery(element).datepicker { dateFormat: 'yy/mm/dd' }
