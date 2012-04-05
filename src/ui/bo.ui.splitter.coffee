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
            
            splitterOuterWidth = $splitter.outerWidth()
            rightXBorderWidth = ($right.outerWidth() - $right.width())
            leftXBorderWidth = ($left.outerWidth() - $left.width())

            leftMinWidth = parseInt($left.css('min-width'), 10)
            rightMinWidth = parseInt($right.css('min-width'), 10)

            leftMinWidth = 10 if isNaN(leftMinWidth) 
            rightMinWidth = 10 if isNaN(rightMinWidth) 

            leftMaxWidth = $parent.width() - (rightMinWidth + rightXBorderWidth + leftXBorderWidth + splitterOuterWidth)
            rightMaxWidth = $parent.width() - (leftMinWidth + leftXBorderWidth + rightXBorderWidth + splitterOuterWidth)

            $left.css  { left: $left.css('left') || 0, right: 'auto',                   top: 0, bottom: 0, position: 'absolute' }
            $right.css { left: 'auto',                 right: $right.css('right') || 0, top: 0, bottom: 0, position: 'absolute' }

            splitterPosition = ko.observable $left.outerWidth()

            recalculate = ->
                desiredLeftWidth = splitterPosition() - leftXBorderWidth
                desiredRightWidth = $parent.width() - splitterPosition() - splitterOuterWidth - rightXBorderWidth

                $left.css('width', Math.min(leftMaxWidth, Math.max(leftMinWidth, desiredLeftWidth)))
                $right.css('width', Math.min(rightMaxWidth, Math.max(rightMinWidth, desiredRightWidth)))
                $splitter.css('left', Math.min(leftMaxWidth + leftXBorderWidth , Math.max(leftMinWidth + leftXBorderWidth, splitterPosition())))

            setContainment = ->
                # Set up draggable
                parentLeftBorder = parseInt($parent.css('border-left-width'), 10)
                parentOffset = $parent.offset()
                sliderLeftWall = parentOffset.left + leftMinWidth + leftXBorderWidth + parentLeftBorder
                sliderRightWall = parentOffset.left + $parent.width() - rightXBorderWidth - parentLeftBorder - rightMinWidth - splitterOuterWidth

                $splitter.draggable 'option', 'containment', [sliderLeftWall, 0, sliderRightWall, 0]
            
            resize = ->
                setContainment()

                desiredRightWidth = $parent.width() - splitterPosition() - splitterOuterWidth - rightXBorderWidth
                
                if Math.min(rightMaxWidth, Math.max(rightMinWidth, desiredRightWidth)) is rightMinWidth
                    splitterPosition $parent.width() - rightMinWidth - splitterOuterWidth - rightXBorderWidth
                else if Math.min(rightMaxWidth, Math.max(rightMinWidth, desiredRightWidth)) is rightMaxWidth
                    splitterPosition $parent.width() - rightMaxWidth - splitterOuterWidth - rightXBorderWidth
                else
                    recalculate()

            splitterPosition.subscribe recalculate

            recalculate()

            $splitter.draggable
                axis: "x"
                drag: (event, ui) ->
                    splitterPosition ui.position.left

            setContainment()

            jQuery(window).on 'resize', resize

            originalLeft = splitterPosition()

            $splitter.on 'dblclick', ->
                splitterPosition originalLeft