!function() {

    bo.log.enabled = true;
    bo.templating.externalPath = '/examples/nerddinner/templates/{name}.html'

    var nerddinner = window.nerddinner = {};

    nerddinner.app = new bo.App()

    nerddinner.app.router.route('Homepage', '/', function() {
        alert("Visited homepage");
    });
    
    nerddinner.app.router.route('Homepage', '/examples/nerddinner', function() {
        nerddinner.app.regionManager.show({ 
            viewName: 'e:homepage', 

            show: function() { 
                this.myName = 'Adam Barclay';
            }
        });
    }); 
    
    nerddinner.app.start();   
}();