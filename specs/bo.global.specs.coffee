beforeEach ->
    window.sinonSandbox = sinon.sandbox.create sinon.getConfig { injectInto: this }

    bo.routing.routes.clear()
    bo.bus.clearAll()

    @respondWithTemplate = (name, body) -> 
        @server.respondWith "GET", "/Templates/Get/#{name}", [200, { "Content-Type": "text/html" }, body]

    @addMatchers
        toBeObservable: ->
            ko.isObservable @actual

        toBeAFunction: ->
            jQuery.isFunction @actual

        toHaveNotBeenCalled: ->
            @actual.called is false

afterEach ->    
    window.sinonSandbox.restore()
