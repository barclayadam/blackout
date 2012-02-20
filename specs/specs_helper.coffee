browserTagCaseIndependentHtml = (html) ->
    jQuery('<div/>').append(html).html()

beforeEach ->
    window.sinonSandbox = sinon.sandbox.create sinon.getConfig { injectInto: this }

    bo.bus.clearAll()
    window.sessionStorage.clear();
    window.localStorage.clear();

    publishSpy = window.sinonSandbox.spy bo.bus, "publish"

    @fixture = jQuery('<div id="fixture" />').appendTo('body')

    @setHtmlFixture = (html) =>
        @fixture.empty()
        jQuery(html).appendTo(@fixture)

    @applyBindingsToHtmlFixture = (viewModel) =>
        ko.applyBindings viewModel, @fixture[0]

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

        toHaveNotBeenPublishedWith: (args) ->
            publishSpy.neverCalledWith @actual, args

    @addMatchers
        toHaveClass: (className) ->
            @message = -> "Expected '#{@actual.selector}' to have CSS class '#{className}'. Has '#{@actual.attr('class')}'."
            @actual.hasClass className

        toNotHaveClass: (className) ->
            @message = -> "Expected '#{@actual.selector}' to not have CSS class '#{className}'."
            (@actual.hasClass className) is false

        toBeVisible: ->
            @message = -> "Expected '#{@actual.selector}' to be visible."

            @actual.is ":visible"

        toBeHidden: ->
            @message = -> "Expected '#{@actual.selector}' to be hidden."

            @actual.is ":hidden"

        toBeSelected: ->
            @actual.is ":selected"

        toBeChecked: ->
            @actual.is ":checked"

        toBeEmpty: ->
            @message = -> "Expected '#{@actual.selector}' to be empty but was #{@actual.html()}."
            @actual.is ":empty"

        toExist: ->
            @message = -> "Expected '#{@actual.selector}' to exist."
            @actual.size() > 0

        toHaveAttr: (attributeName, expectedAttributeValue) ->
            @message = -> "Expected #{@actual.selector} to have attribute '#{attributeName}' with value '#{expectedAttributeValue}', was '#{@actual.attr(attributeName)}'."
            @actual.attr(attributeName) is expectedAttributeValue

        toHaveId: (id) ->
            @message = -> "Expected #{@actual.selector} to have id '#{id}' was '#{@actual.attr("id")}'."
            @actual.attr("id") is id

        toHaveHtml: (html) ->
            @message = -> "Expected #{@actual.selector} to have HTML '#{html}' but was '#{@actual.html()}'."
            @actual.html() is browserTagCaseIndependentHtml html

        toHaveText: (text) ->
            @message = -> "Expected #{@actual.selector} to be have text '#{text}', but was '#{@actual.text()}'."

            if text and jQuery.isFunction(text.test)
                text.test @actual.text()
            else
                @actual.text() is text

        toHaveValue: (value) ->
            @actual.val() is value

        toBeDisabled: (selector) ->
            @message = -> "Expected #{@actual.selector} to be disabled."
            @actual.is(":disabled") or @actual.attr("aria-disabled") is "true"

        toBeEnabled: (selector) ->
            @message = -> "Expected #{@actual.selector} to be enabled."
            not (@actual.is(":disabled") or @actual.attr("aria-disabled") is "true")

afterEach ->    
    window.sinonSandbox.restore()
    jQuery('#fixture').remove()
