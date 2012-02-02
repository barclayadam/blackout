# reference "bo.coffee"

ko.bindingHandlers.datepicker =
    init: (element, valueAccessor, allBindingsAccessor) ->
        ko.bindingHandlers.value.init element, valueAccessor, allBindingsAccessor

        value = valueAccessor()
        validationRules = value?.validationRules

        if validationRules?
            maxDate = validationRules.maxDate if validationRules.maxDate?
            minDate = validationRules.minDate if validationRules.minDate?

            minDate = '+1d' if validationRules.inFuture?
            maxDate = '-1d' if validationRules.inPast?  
            
            maxDate = new Date() if validationRules.notInFuture?
            minDate = new Date() if validationRules.notInPast?

        jQuery(element).datepicker 
            dateFormat: 'dd/mm/yy'

            minDate: minDate
            maxDate: maxDate 

    update: (element, valueAccessor, allBindingsAccessor) ->
        ko.bindingHandlers.value.update element, valueAccessor, allBindingsAccessor

