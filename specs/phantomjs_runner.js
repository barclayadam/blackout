// https://github.com/detro/phantomjs-jasminexml-example

phantom.injectJs("lib/utils/core.js");

if ( phantom.args.length !== 2 ) {
    console.log("Usage: phantom_test_runner.js HTML_RUNNER OUTPUT_IMAGE");
    phantom.exit();
} else {
    var htmlrunner = phantom.args[0],
        outputImage = phantom.args[1],
        page = new WebPage();
         
    page.onConsoleMessage = function(msg, source, linenumber) {
        console.log(msg);
    };    

    page.open(htmlrunner, function (status) {
        console.log("Test runner page loaded with status " + status);
        
        if (status === "success") {
            utils.core.waitfor(function () { // wait for this to be true
                return page.evaluate(function () {
                    return typeof (jasmine.TeamCityReporter.done) !== "undefined";
                });
            }, function () { // once done...
                console.log("Finished executing tests.");

                page.render(outputImage)
                
                // Return the correct exit status. '0' only if all the tests passed
                phantom.exit(page.evaluate(function () {
                    return jasmine.TeamCityReporter.testsHaveFailed ? 1 : 0; //< exit(0) is success, exit(1) is failure
                }));
            }, function () { // or, once it times out...
                console.log("Tests have timed out.");
                phantom.exit(1);
            });
        } else {
            console.log("phantomjs> Could not load '" + htmlrunner + "'.");
            phantom.exit(1);
        }
    });
}