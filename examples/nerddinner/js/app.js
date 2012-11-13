bo.log.enabled = true;
bo.templating.externalPath = '/examples/nerddinner/templates/{name}.html'

var nerddinner = window.nerddinner = {};

nerddinner.app = new bo.App()

bo.bus.subscribe('routeNavigated', function(msg) {
	if(msg.options) {
		nerddinner.app.regionManager.show(msg.options);
	}
})

jQuery(function() {
    nerddinner.app.start();   
});