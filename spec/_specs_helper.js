beforeEach(function () {
    window.sinonSandbox = sinon.sandbox.create(sinon.getConfig({
        injectInto: this,
        useFakeTimers: false
    }));

    bo.bus.clearAll();
    bo.templating.reset();

    window.sessionStorage.clear();
    window.localStorage.clear();

    this.setHtmlFixture = function (html) {
        setFixtures(html);
    };

    this.applyBindingsToFixture = function (viewModel) {
        ko.applyBindings(viewModel, document.getElementById('jasmine-fixture'));
    };

    this.respondWithTemplate = function (path, body) {
        this.server.respondWith("GET", path, [
            200, {
                "Content-Type": "text/html"
            },
            body]);
    };
});

afterEach(function () {
    window.sinonSandbox.restore();
});