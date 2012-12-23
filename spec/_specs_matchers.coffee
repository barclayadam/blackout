browserTagCaseIndependentHtml = (html) ->
    jQuery('<div/>').append(html).html()

beforeEach ->
    publishSpy = window.sinonSandbox.spy bo.bus, "publish"
    
    @addMatchers
        toBeAPromise: ->
            @actual? and @actual.done? and @actual.fail?

        toBeObservable: ->
            ko.isObservable @actual

        toBeAnObservableArray: ->
            ko.isObservable(@actual) and _.isArray @actual()

        toBeAFunction: ->
            _.isFunction @actual

        toHaveNotBeenCalled: ->
            @actual.called is false

        toBeAnArray: ->
            _.isArray @actual 

        toBeAnEmptyArray: ->
             @actual.length is 0

        toHaveBeenPublished: ->
            publishSpy.calledWith @actual

        toHaveBeenPublishedOnce: ->
            publishSpy.calledOnceWith @actual

        toHaveBeenPublishedWith: (args) ->
            publishSpy.calledWith @actual, args

        toHaveNotBeenPublished: ->
            not (publishSpy.calledWith @actual)

        toHaveNotBeenPublishedWith: (args) ->
            publishSpy.neverCalledWith @actual, args
