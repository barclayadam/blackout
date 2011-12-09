currentlyDraggingViewModel = {
    currentlyDragging: ko.observable(),
    canDrop: ko.observable()
    dropTarget: ko.observable()
}

ko.bindingHandlers.draggable =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        $element = jQuery element
        node = viewModel
        value = ko.utils.unwrapObservable(valueAccessor() || {})

        if value.template
            value.helper = ->
                helper = jQuery('<div id="custom-draggable-helper" />')

                _.defer ->
                    ko.renderTemplate value.template, currentlyDraggingViewModel, {}, helper[0], "replaceChildren"

                helper

        dragOptions =
            revert: 'invalid'
            revertDuration: 250
            appendTo: 'body'
            helper: 'clone'
            zIndex: 200000
            distance: 10

            start: (e, ui) ->
                currentlyDraggingViewModel.canDrop false
                currentlyDraggingViewModel.dropTarget undefined
                currentlyDraggingViewModel.currentlyDragging node

                $element.attr "aria-grabbed", true

            stop: () ->
                $element.attr "aria-grabbed", false

                _.defer ->
                    currentlyDraggingViewModel.currentlyDragging undefined

        $element.draggable jQuery.extend {}, dragOptions, value
        $element.attr "aria-grabbed", false

    update: () ->
        jQuery("body").toggleClass "ui-drag-in-progress", currentlyDraggingViewModel.currentlyDragging() isnt undefined

ko.bindingHandlers.dropTarget =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        $element = jQuery element
        value = valueAccessor() || {}
        canAccept = ko.utils.unwrapObservable value.canAccept
        handler = ko.utils.unwrapObservable value.onDropComplete

        dropOptions =
            greedy: true
            tolerance: 'pointer'
            hoverClass: 'ui-hovered-drop-target'

            accept: () ->
                canAccept.call viewModel, currentlyDraggingViewModel.currentlyDragging()

            over: () ->
                canAcceptDrop = canAccept.call viewModel, currentlyDraggingViewModel.currentlyDragging()

                currentlyDraggingViewModel.canDrop canAcceptDrop
                currentlyDraggingViewModel.dropTarget viewModel

            out: () ->
                currentlyDraggingViewModel.canDrop false
                currentlyDraggingViewModel.dropTarget undefined

            drop: () ->
                _.defer ->
                    handler.call viewModel, currentlyDraggingViewModel.currentlyDragging()

        $element.droppable jQuery.extend {}, dropOptions, value

    update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        $element = jQuery element
        value = valueAccessor() || {}
        canAccept = ko.utils.unwrapObservable value.canAccept
        dropEffect = ko.utils.unwrapObservable (value.dropEffect || "move")

        if currentlyDraggingViewModel.currentlyDragging()?
            canAccept = canAccept.call viewModel, currentlyDraggingViewModel.currentlyDragging()
            $element.toggleClass "ui-valid-drop-target", canAccept
            $element.toggleClass "ui-invalid-drop-target", !canAccept

            if canAccept
                $element.attr "aria-dropeffect", dropEffect
             else
                $element.attr "aria-dropeffect", "none"
        else
            $element.removeClass "ui-valid-drop-target"
            $element.removeClass "ui-invalid-drop-target"
