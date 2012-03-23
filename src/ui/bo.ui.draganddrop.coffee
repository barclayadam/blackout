draggableModel =
    currentlyDragging: ko.observable()
    canDrop: ko.observable()
    dropTarget: ko.observable()

ko.bindingHandlers.draggable =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        $element = jQuery element
        value = ko.utils.unwrapObservable(valueAccessor())

        if value is false or (value.enabled ? true) is false
            return

        if value.template
            value.helper = ->
                helper = jQuery("""<div data-bind='css: { "can-drop": canDrop }, template: "#{value.template}"' />""")

                _.defer ->
                    ko.applyBindings draggableModel, helper[0]

                helper

        dragOptions =
            revert: 'invalid'
            revertDuration: 250
            appendTo: 'body'
            helper: 'clone'
            zIndex: 200000
            distance: 10
            cursorAt: { left: 5 }

            start: (e, ui) ->
                draggableModel.canDrop false
                draggableModel.dropTarget undefined
                draggableModel.currentlyDragging viewModel

                $element.attr "aria-grabbed", true

            stop: () ->
                $element.attr "aria-grabbed", false

                _.defer ->
                    draggableModel.currentlyDragging undefined

        $element.draggable jQuery.extend {}, dragOptions, value
        $element.attr "aria-grabbed", false

    update: () ->
        jQuery("body").toggleClass "ui-drag-in-progress", draggableModel.currentlyDragging()?

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
                if draggableModel.currentlyDragging()?
                    canAccept.call viewModel, draggableModel.currentlyDragging()
                else
                    false

            over: () ->
                canAcceptDrop = canAccept.call viewModel, draggableModel.currentlyDragging()

                draggableModel.canDrop canAcceptDrop
                draggableModel.dropTarget viewModel

            out: () ->
                draggableModel.canDrop false
                draggableModel.dropTarget undefined

            drop: () ->
                _.defer ->
                    handler.call viewModel, draggableModel.currentlyDragging()

        $element.droppable jQuery.extend {}, dropOptions, value

    update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        $element = jQuery element
        value = valueAccessor() || {}
        canAccept = ko.utils.unwrapObservable value.canAccept
        dropEffect = ko.utils.unwrapObservable (value.dropEffect || "move")

        if draggableModel.currentlyDragging()?
            canAccept = canAccept.call viewModel, draggableModel.currentlyDragging()
            $element.toggleClass "ui-valid-drop-target", canAccept
            $element.toggleClass "ui-invalid-drop-target", !canAccept

            if canAccept
                $element.attr "aria-dropeffect", dropEffect
             else
                $element.attr "aria-dropeffect", "none"
        else
            $element.removeClass "ui-valid-drop-target"
            $element.removeClass "ui-invalid-drop-target"
