beforeEach ->
    publishSpy = window.sinonSandbox.spy bo.bus, "publish"
    
    @addMatchers
        toBeAPromise: ->
            @actual? and @actual.done? and @actual.fail?

        toBeObservable: ->
            ko.isObservable @actual

        toBeAnObservableArray: ->
            ko.isObservable(@actual) and _.isArray @actual()

        toBeAFunction: ->
            _.isFunction @actual

        toHaveNotBeenCalled: ->
            @actual.called is false

        toBeAnArray: ->
            _.isArray @actual 

        toBeAnEmptyArray: ->
             @actual.length is 0

        toHaveBeenPublished: ->
            publishSpy.calledWith @actual

        toHaveBeenPublishedOnce: ->
            publishSpy.calledOnceWith @actual

        toHaveBeenPublishedWith: (args) ->
            publishSpy.calledWith @actual, args

        toHaveNotBeenPublished: ->
            not (publishSpy.calledWith @actual)

        toHaveNotBeenPublishedWith: (args) ->
            publishSpy.neverCalledWith @actual, args

    @addMatchers
        toHaveClass: (className) ->
            @message = -> "Expected '#{$(@actual).selector}' to have CSS class '#{className}'. Has '#{$(@actual).attr('class')}'."
            $(@actual).hasClass className

        toNotHaveClass: (className) ->
            @message = -> "Expected '#{$(@actual).selector}' to not have CSS class '#{className}'."
            ($(@actual).hasClass className) is false

        toBeVisible: ->
            @message = -> "Expected '#{$(@actual).selector}' to be visible."

            $(@actual).is ":visible"

        toBeHidden: ->
            @message = -> "Expected '#{$(@actual).selector}' to be hidden."

            $(@actual).is ":hidden"

        toBeSelected: ->
            $(@actual).is ":selected"

        toBeChecked: ->
            $(@actual).is ":checked"

        toBeEmpty: ->
            @message = -> "Expected '#{$(@actual).selector}' to be empty but was #{$(@actual).html()}."
            $(@actual).is ":empty"
        
        toNotBeEmpty: ->
            @message = -> "Expected '#{$(@actual).selector}' to not be empty."
            not $(@actual).is ":empty"

        toExist: ->
            @message = -> "Expected '#{$(@actual).selector}' to exist."
            $(@actual).size() > 0

        toHaveAttr: (attributeName, expectedAttributeValue) ->
            @message = -> "Expected #{$(@actual).selector} to have attribute '#{attributeName}' with value '#{expectedAttributeValue}', was '#{$(@actual).attr(attributeName)}'."

            if expectedAttributeValue?
                
                $(@actual).attr(attributeName)? and $(@actual).attr(attributeName).toString() is expectedAttributeValue.toString()
            else
                $(@actual).attr(attributeName)?

        toHaveId: (id) ->
            @message = -> "Expected #{$(@actual).selector} to have id '#{id}' was '#{$(@actual).attr("id")}'."
            $(@actual).attr("id") is id

        toHaveHtml: (html) ->
            @message = -> "Expected #{$(@actual).selector} to have HTML '#{html}' but was '#{$(@actual).html()}'."
            $(@actual).html() is browserTagCaseIndependentHtml html

        toHaveText: (text) ->
            @message = -> "Expected #{$(@actual).selector} to be have text '#{text}', but was '#{$(@actual).text()}'."

            if text and $.isFunction(text.test)
                text.test $(@actual).text()
            else
                $(@actual).text() is text

        toHaveValue: (value) ->
            $(@actual).val() is value

        toBeDisabled: (selector) ->
            @message = -> "Expected #{$(@actual).selector} to be disabled."
            $(@actual).is(":disabled") or $(@actual).attr("aria-disabled") is "true"

        toBeEnabled: (selector) ->
            @message = -> "Expected #{$(@actual).selector} to be enabled."
            not ($(@actual).is(":disabled") or $(@actual).attr("aria-disabled") is "true")
