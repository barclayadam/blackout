bo.log = 
    enabled: false

# We attempt to use console.log to determine availability
# and safety of use, setting `console` to an empty object
# in the instance of failure.
try
    window.console.log()
catch e
    window.console = {}


# For the given `levels` will create a logging method
# on the `bo.log` object to be used to log:
#
# * debug
# * info
# * warn
# * error
'debug info warn error'.replace /\w+/g, (n) ->
    # The method used to alias through to the `console.log`
    # method if available, or to fail silently if no logging
    # mechanism is built-in to the browser.
    #
    # Note this does also fail in IE8/9 as the `apply` functionality
    # is not available on the `console.[n]` functions.
    bo.log[n] = -> 
        if bo.log.enabled
            (window.console[n] || window.console.log || ->).apply? window.console, arguments