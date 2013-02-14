bo.App = (function() {
    function App() {
        this.regionManager = new bo.RegionManager();
        this.router = new bo.routing.Router();
    }

    App.prototype.start = function() {
        var _this = this;
        
        bo.log.info("Starting application");
        bo.location.initialise();

        bo.bus.subscribe('routeNavigated', function(msg) {
          if (msg.options != null) {
            _this.regionManager.show(msg.options);
          }
        });
    };

    return App;

})();

koBindingHandlers.app = {
    init: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var app = valueAccessor();
        
        koBindingHandlers.regionManager.init(element, (function() {
            return app.regionManager;
        }), allBindingsAccessor, viewModel, bindingContext);
        
        app.start();

        return { controlsDescendantBindings: true };
    }
};
