(function(window, document, $, ko) {
    (function(factory) {
        // Support three module loading scenarios
        if (typeof require === "function" && typeof exports === "object" && typeof module === "object") {
            // [1] CommonJS/Node.js
            factory(module["exports"] || exports);
        } else if (typeof define === "function" && define["amd"]) {
            // [2] AMD anonymous module
            define(["exports"], factory);
        } else {
            // [3] No module loader (plain <script> tag) - put directly in global namespace
            factory(window["bo"] = {});
        }
    })(function(boExports) {
        if (ko === void 0) {
            throw new Error('knockout must be included before blackout.');
        }

        // Declare some common variables used throughout the library
        // to help reduce minified size.
        var koBindingHandlers = ko.bindingHandlers;

        // Root namespace into which the public API will be exported.
        var bo = boExports != null ? boExports : {};

        //= core/bo.log.js

        //= core/bo.utils.js
        //= core/bo.bus.js
        //= core/bo.uri.js
        //= core/bo.ajax.js
        //= core/bo.sorting.js
        //= core/bo.storage.js
        //= core/bo.notifications.js
        //= core/bo.templating.js
        //= core/bo.validation.js
        //= core/bo.validation.rules.js
        //= core/bo.dataSource.js
        //= core/bo.location.js
        //= core/bo.routing.js
                
        //= core/bo.tagBindingsProvider.js
        //= core/bo.viewModel.js

        //= core/bo.app.js

        //= messaging/bo.messaging.query.js
        //= messaging/bo.messaging.command.js

        //= ui/bo.ui.uiaction.js
        //= ui/bo.ui.partBindingHandler.js
        //= ui/bo.ui.regionManager.js

        // Once everything has been loaded we bootstrap, which simply involvs attempting
        // to bind the current document, which will find any app binding handler definitions
        // which kicks off the 'app' semantics of a Blackout application.

        // TODO: Remove jQuery dependency
        $(document).ready(function() {
            ko.applyBindings({});
        });
    });
})(window, document, window["jQuery"], window["ko"]);