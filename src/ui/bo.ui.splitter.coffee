# reference "bo.coffee"
ko.bindingHandlers.splitter =
    init:  (element, valueAccessor) ->
        _.defer -> 
            options = valueAccessor()
            options = _.defaults options, { outline: true, resizeToWidth: true }

            options.type = if options.type is 'vertical' then 'v' else 'h'

            $splitter = jQuery(element)

            if $splitter.children().length is 2
                $splitter.splitter options
