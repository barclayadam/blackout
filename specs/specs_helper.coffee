browserTagCaseIndependentHtml = (html) ->
    jQuery('<div/>').append(html).html()

beforeEach ->
    window.sinonSandbox = sinon.sandbox.create sinon.getConfig { injectInto: this }

    bo.bus.clearAll()

    publishSpy = window.sinonSandbox.spy bo.bus, "publish"

    @respondWithTemplate = (path, body) ->
        @server.respondWith "GET", path, [200, { "Content-Type": "text/html" }, body]

    @addMatchers
        toBeObservable: ->
            ko.isObservable @actual

        toBeAnObservableArray: ->
            ko.isObservable(@actual) and @actual().length isnt undefined

        toBeAFunction: ->
            jQuery.isFunction @actual

        toHaveNotBeenCalled: ->
            @actual.called is false

        toBeAnArray: ->
            _.isArray @actual

        toBeAnEmptyArray: ->
            @actual.length is 0

        toHaveBeenPublished: ->
            publishSpy.calledWith @actual

        toHaveBeenPublishedWith: (args) ->
            publishSpy.calledWith @actual, args

        toHaveNotBeenPublished: ->
            not (publishSpy.calledWith @actual)

    @fixture = jQuery('<div id="fixture" />').appendTo('body')

    @addMatchers
        toHaveClass: (className) ->
            @message = -> "Expected #{@actual.selector} to have CSS class '#{className}'."
            @actual.hasClass className

        toNotHaveClass: (className) ->
            @message = -> "Expected #{@actual.selector} to not have CSS class '#{className}'."
            (@actual.hasClass className) is false

        toBeVisible: ->
            @actual.is ":visible"

        toBeHidden: ->
            @actual.is ":hidden"

        toBeSelected: ->
            @actual.is ":selected"

        toBeChecked: ->
            @actual.is ":checked"

        toBeEmpty: ->
            @message = -> "Expected #{@actual.selector} to be empty but was #{@actual.html()}."
            @actual.is ":empty"

        toExist: ->
            @actual.size() > 0

        toHaveAttr: (attributeName, expectedAttributeValue) ->
            hasProperty @actual.attr(attributeName), expectedAttributeValue

        toHaveId: (id) ->
            @actual.attr("id") is id

        toHaveHtml: (html) ->
            @message = -> "Expected #{@actual.selector} to have HTML '#{html}' but was '#{@actual.html()}'."
            @actual.html() is browserTagCaseIndependentHtml html

        toHaveText: (text) ->
            if text and jQuery.isFunction(text.test)
                text.test @actual.text()
            else
                @actual.text() is text

        toHaveValue: (value) ->
            @actual.val() is value

        toBeDisabled: (selector) ->
            @actual.is ":disabled"

afterEach ->    
    window.sinonSandbox.restore()
    jQuery('#fixture').remove()
