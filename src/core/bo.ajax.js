var RequestBuilder, ajax, listening, requestDetectionFrame;

ajax = bo.ajax = {};

/*
 Used to store any request promises that are executed, to
 allow the `bo.ajax.listen` function to capture the promises that
 are executed during a function call to be able to generate a promise
 that is resolved when all requests have completed.
*/
requestDetectionFrame = [];
listening = false;

RequestBuilder = (function() {

    function doCall(httpMethod, requestBuilder) {
        /*
            TODO: Extract extension of deferred to give non-failure
            handling semantics that could be used elsewhere.
        */
        var ajaxRequest, failureHandlerRegistered, getDeferred, promise, requestOptions;

        getDeferred = $.Deferred();
        promise = getDeferred.promise();

        failureHandlerRegistered = false;

        requestOptions = _.defaults(requestBuilder.properties, {
            url: requestBuilder.url,
            type: httpMethod
        });

        ajaxRequest = $.ajax(requestOptions);

        bo.bus.publish("ajaxRequestSent:" + requestBuilder.url, {
            path: requestBuilder.url,
            method: httpMethod
        });

        ajaxRequest.done(function(response) {
              bo.bus.publish("ajaxResponseReceived:success:" + requestBuilder.url, {
                    path: requestBuilder.url,
                    method: httpMethod,
                    response: response,
                    status: 200,
                    success: true
              });

              return getDeferred.resolve(response);
        });

        ajaxRequest.fail(function(response) {
            var failureMessage = {
                path: requestBuilder.url,
                method: httpMethod,
                responseText: response.responseText,
                status: response.status,
                success: false
            };

            bo.bus.publish("ajaxResponseReceived:failure:" + requestBuilder.url, failureMessage);
            
            if (!failureHandlerRegistered) {
                bo.bus.publish("ajaxResponseFailureUnhandled:" + requestBuilder.url, failureMessage);
            }
            
            return getDeferred.reject(response);
        });

        promise.fail = function(callback) {
              failureHandlerRegistered = true;

              return getDeferred.fail(callback);
        };

        promise.then = function(success, failure) {
              failureHandlerRegistered = failureHandlerRegistered || (failure != null);

              return getDeferred.then(success, failure);
        };

        if (listening) {
            requestDetectionFrame.push(promise);
        }

        return promise;
    };

    function RequestBuilder(url) {
        this.url = url;
        this.properties = {};
    }

    RequestBuilder.prototype.data = function(data) {
        this.properties.data = ko.toJSON(data);
        return this;
    };

    RequestBuilder.prototype.get = function() {
        return doCall('GET', this);
    };

    RequestBuilder.prototype.post = function() {
        return doCall('POST', this);
    };

    RequestBuilder.prototype.put = function() {
        return doCall('PUT', this);
    };

    RequestBuilder.prototype["delete"] = function() {
        return doCall('DELETE', this);
    };

    RequestBuilder.prototype.head = function() {
        return doCall('HEAD', this);
    };

    return RequestBuilder;
})();

/**
    Entry point to the AJAX API, which begins the process
    of 'building' a call to a server using an AJAX call. This
    method returns a `request builder` that has a number of methods
    on it that allows further setting of data, such as query
    strings (if not already supplied), form data and content types.

    The AJAX API is designed to provide a simple method of entry to
    creating AJAX calls, to allow composition of calls if necessary (by
    passing the request builder around), and to provide the familiar semantics
    of publishing events as used extensively throughout `blackout`.
*/
ajax.url = function(url) {
    return new RequestBuilder(url);
};

/**
    Provides a way of listening to all AJAX requests during the execution
    of a method and executing a callback based on the result of all those
    captured requests.

    In the case where multiple requests are executed the method returns the 
    `promise` that tracks the aggregate state of all requests. The method will 
    resolve this `promise` as soon as all the requests resolve, or reject the 
    `promise` as one of the requests is rejected. 

    If all requests are successful (resolved), the `done` / `then` callbacks will
    be resolved with the values of all the requests, in the order they were
    executed.

    In the case of multiple requests where one of the requests fails, the failure
    callbacks of the returned `promise` will be immediately executed. This means
    that some of the AJAX requests may still be 'in-flight' at the time of
    failure execution.
*/
ajax.listen = function(f) {
    // Ensure we do not pick up previous requests.

    var allFinishedPromise;
    requestDetectionFrame = [];

    listening = true;
    f();
    listening = false;

    allFinishedPromise = $.when.apply(this, requestDetectionFrame);

    allFinishedPromise.then(function() {
        requestDetectionFrame = [];
    });

    return allFinishedPromise;
};