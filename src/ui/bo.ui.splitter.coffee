# reference "bo.coffee"
ko.bindingHandlers.splitter =
    init:  (element, valueAccessor) ->
        _.defer -> 
            $splitter = jQuery(element)

            if $splitter.children().length is 2
                $splitter.splitter( { resizeToWidth: true } )