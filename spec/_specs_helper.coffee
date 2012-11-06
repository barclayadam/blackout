browserTagCaseIndependentHtml = (html) ->
    $('<div/>').append(html).html()

beforeEach ->
    window.sinonSandbox = sinon.sandbox.create sinon.getConfig { injectInto: this, useFakeTimers: false }

    bo.bus.clearAll()
    bo.templating.reset()
    window.sessionStorage.clear()
    window.localStorage.clear()
    
    @fixture = $('<div id="fixture" />').appendTo('body')

    @setHtmlFixture = (html) =>
        @fixture.empty()
        $(html).appendTo(@fixture)

    @applyBindingsToHtmlFixture = (viewModel) =>
        ko.applyBindings viewModel, @fixture[0]

    @respondWithTemplate = (path, body) ->
        @server.respondWith "GET", path, [200, { "Content-Type": "text/html" }, body]

afterEach ->    
    window.sinonSandbox.restore()
    $('#fixture').remove()
