ajax = bo.ajax = {}

# Used to store any request promises that are executed, to
# allow the `bo.ajax.listen` function to capture the promises that
# are executed during a function call to be able to generate a promise
# that is resolved when all requests have completed.
requestDetectionFrame = []

class RequestBuilder
    doCall = (httpMethod, requestBuilder) ->
        # TODO: Extract extension of deferred to give non-failure
        # handling semantics that could be used elsewhere.
        getDeferred = $.Deferred()
        failureHandlerRegistered = false

        requestOptions = _.defaults requestBuilder.properties,
            url: requestBuilder.url
            type: httpMethod

        ajaxRequest = $.ajax requestOptions

        bo.bus.publish "ajaxRequestSent:#{requestBuilder.url}", 
            path: requestBuilder.url
            method: httpMethod

        ajaxRequest.done (response) ->
            bo.bus.publish "ajaxResponseReceived:success:#{requestBuilder.url}", 
                path: requestBuilder.url
                method: httpMethod
                response: response
                status: 200

            getDeferred.resolve response

        ajaxRequest.fail (response) ->
            failureMessage =
                path: requestBuilder.url
                method: httpMethod
                responseText: response.responseText
                status: response.status

            bo.bus.publish "ajaxResponseReceived:failure:#{requestBuilder.url}", failureMessage

            if not failureHandlerRegistered
                bo.bus.publish "ajaxResponseFailureUnhandled:#{requestBuilder.url}", failureMessage

            getDeferred.reject response

        promise = getDeferred.promise()

        promise.fail = (callback) ->
            failureHandlerRegistered = true

            getDeferred.fail callback

        requestDetectionFrame.push promise

        promise

    constructor: (@url) ->
        @properties = {}

    get: () ->
        doCall 'GET', @

    post: () ->
        doCall 'POST', @

    put: () ->
        doCall 'PUT', @

    delete: () ->
        doCall 'DELETE', @

    head: () ->
        doCall 'HEAD', @

# Entry point to the AJAX API, which begins the process
# of 'building' a call to a server using an AJAX call. This
# method returns a `request builder` that has a number of methods
# on it that allows further setting of data, such as query
# strings (if not already supplied), form data and content types.
#
# The AJAX API is designed to provide a simple method of entry to
# creating AJAX calls, to allow composition of calls if necessary (by
# passing the request builder around), and to provide the familiar semantics
# of publishing events as used extensively throughout `boson`.
ajax.url = (url) ->
    new RequestBuilder url

# Provides a way of listening to all AJAX requests during the execution
# of a method and executing a callback based on the result of all those
# captured requests.
#
# In the case where multiple requests are executed the method returns the 
# `promise` that tracks the aggregate state of all requests. The method will 
# resolve this `promise` as soon as all the requests resolve, or reject the 
# `promise` as one of the requests is rejected. 
#
# If all requests are successful (resolved), the `done` / `then` callbacks will
# be resolved with the values of all the requests, in the order they were
# executed.
#
# In the case of multiple requests where one of the requests fails, the failure
# callbacks of the returned `promise` will be immediately executed. This means
# that some of the AJAX requests may still be 'in-flight' at the time of
# failure execution.
ajax.listen = (f) ->
    requestDetectionFrame = []

    f()

    $.when.apply(@, requestDetectionFrame)