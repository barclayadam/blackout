browserTagCaseIndependentHtml = (html) ->
    $('<div/>').append(html).html()

beforeEach ->
    window.sinonSandbox = sinon.sandbox.create sinon.getConfig { injectInto: this, useFakeTimers: false }

    bo.bus.clearAll()
    bo.templating.reset()
    window.sessionStorage.clear()
    window.localStorage.clear()
    
    @setHtmlFixture = (html) =>
        setFixtures html

    @applyBindingsToFixture = (viewModel) =>
        ko.applyBindings viewModel, document.getElementById 'jasmine-fixture'

    @respondWithTemplate = (path, body) ->
        @server.respondWith "GET", path, [200, { "Content-Type": "text/html" }, body]

afterEach ->    
    window.sinonSandbox.restore()
