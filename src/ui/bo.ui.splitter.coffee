# reference "bo.coffee"

ko.bindingHandlers.splitter =
    init:  (element, valueAccessor) ->
        _.defer ->
            value = valueAccessor()
            enabled = value.enabled

            $splitter = jQuery(element)
            $parent = $splitter.parent()
            $left = $splitter.prev()
            $right = $splitter.next()

            if(!$left.is(':visible') or !$right.is(':visible'))
                return

            $splitter.addClass('splitter')
            parentWidth = $parent.width()

            splitterOuterWidth = $splitter.outerWidth()
            rightXBorderWidth = ($right.outerWidth() - $right.width())
            leftXBorderWidth = ($left.outerWidth() - $left.width())

            leftMinWidth = parseInt($left.css('min-width'), 10)
            rightMinWidth = parseInt($right.css('min-width'), 10)

            leftMaxWidth = $parent.width() - (rightMinWidth + rightXBorderWidth + leftXBorderWidth + splitterOuterWidth)
            rightMaxWidth = $parent.width() - (leftMinWidth + leftXBorderWidth + rightXBorderWidth + splitterOuterWidth)

            $left.css { left: 0, top: 0, bottom: 0, position: 'absolute' }
            $right.css  { right: 0, top: 0, bottom: 0, position: 'absolute' }

            splitterPosition = ko.observable $left.outerWidth()

            ko.computed ->
                desiredLeftWidth = splitterPosition() - leftXBorderWidth
                desiredRightWidth = parentWidth - splitterPosition() - splitterOuterWidth - rightXBorderWidth

                $left.css('width', Math.min(leftMaxWidth, Math.max(leftMinWidth, desiredLeftWidth)))
                $right.css('width', Math.min(rightMaxWidth, Math.max(rightMinWidth, desiredRightWidth)))
                $splitter.css('left', Math.min(leftMaxWidth + leftXBorderWidth , Math.max(leftMinWidth + leftXBorderWidth, splitterPosition())))

            # Set up draggable
            parentLeftBorder = parseInt($parent.css('border-left-width'), 10)
            parentOffset = $parent.offset()
            sliderLeftWall = parentOffset.left + leftMinWidth + leftXBorderWidth + parentLeftBorder
            sliderRightWall = parentOffset.left + parentWidth - rightXBorderWidth - parentLeftBorder - rightMinWidth - splitterOuterWidth

            $splitter.draggable
                axis: "x"
                containment: [sliderLeftWall, 0, sliderRightWall, 0]
                drag: (event, ui) ->
                    splitterPosition ui.position.left