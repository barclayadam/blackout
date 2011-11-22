/// <reference path="../jasmine/jasmine.js"/>

(function () {
    jasmine.TeamCityReporter = function () {
        this.testSuites = {};
        this.testSpecs = {};
        this.testRun = {
            suites: []
        };
    };

    jasmine.TeamCityReporter.prototype = {
        reportRunnerStarting: function (runner) {
            var suites = runner.suites();

            for (var i = 0; i < suites.length; i++) {
                var currentSuite = suites[i];

                var suite = {
                    name: currentSuite.description
                };

                this.testSuites[currentSuite.id] = suite;
            }
        },

        reportRunnerResults: function (runner) {
            jasmine.TeamCityReporter.done = true;
        },

        reportSuiteResults: function (suite) {
            console.log("##teamcity[testSuiteFinished name='" + suite.description + "']");
        },

        reportSpecStarting: function (spec) {
            if (!spec.suite.seen) {
                console.log("##teamcity[testSuiteStarted name='" + spec.suite.description + "']");
                spec.suite.seen = true;
            }

            console.log("##teamcity[testStarted name='" + spec.description + "']");
        },

        reportSpecResults: function (spec) {
            if (spec.results().failedCount > 0) {
                jasmine.TeamCityReporter.testsHaveFailed = true;
                
                var items = spec.results().getItems(),
                    assertionFailures = [];

                for (var i = 0; i < items.length; i++) {
                    var result = items[i];
                    if (!result.passed()) {
                        assertionFailures.push(result.message + " @ " + result.trace.stack ? result.trace.stack : "[Unknown]");
                    }
                }

                console.log("##teamcity[testFailed name='" + spec.description + "'" + " message='" + assertionFailures.join() + "']");
            }

            console.log("##teamcity[testFinished name='" + spec.description + "']");
        }
    };
})();