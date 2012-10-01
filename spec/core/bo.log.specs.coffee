levelMethodSpecs = ((method) ->
    describe "#{method} - enabled", ->
        beforeEach ->
            bo.log.enabled = true

        afterEach ->
            bo.log.enabled = false
                    
        # Note the 'hack' to check for existence of apply method. A little
        # internal implementation leaking for sake of IE8/9
        if console?[method]?.apply?
            describe 'when direct console equivalent is available', ->
                beforeEach ->
                    @logStub = @stub console, method

                    bo.log[method] 'An Argument', 'Another Argument'

                it 'should direct calls to the built-in console method', ->
                    expect(@logStub).toHaveBeenCalledWith 'An Argument', 'Another Argument'
        else if console?.log?.apply?
            describe 'when console.log is available', ->
                beforeEach ->
                    @logStub = @stub console, 'log'

                    bo.log[method] 'An Argument', 'Another Argument'

                it 'should direct calls to the built-in console.log method', ->
                    expect(@logStub).toHaveBeenCalledWith 'An Argument', 'Another Argument'
        else
            describe 'when console.log is not available', ->
                it 'should not fail to execute logging methods', ->
                    # Just execute to ensure no failures
                    bo.log[method] 'An Argument', 'Another Argument'

    describe "#{method} - disabled", ->
        beforeEach ->
            bo.log.enabled = false

        afterEach ->
            bo.log.enabled = false
                    
        # Note the 'hack' to check for existence of apply method. A little
        # internal implementation leaking for sake of IE8/9
        if console?[method]?.apply?
            describe 'when direct console equivalent is available', ->
                beforeEach ->
                    @logStub = @stub console, method

                    bo.log[method] 'An Argument', 'Another Argument'

                it 'should not direct calls to the built-in console method', ->
                    expect(@logStub).toHaveNotBeenCalled()
        else if console?.log?.apply?
            describe 'when console.log is available', ->
                beforeEach ->
                    @logStub = @stub console, 'log'

                    bo.log[method] 'An Argument', 'Another Argument'

                it 'should not direct calls to the built-in console.log method', ->
                    expect(@logStub).toHaveNotBeenCalled()
)

describe 'logger', ->
    levelMethodSpecs 'debug'
    levelMethodSpecs 'info'
    levelMethodSpecs 'warn'
    levelMethodSpecs 'error'