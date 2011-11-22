window.bo = {}
window.bo.ui = {}

window.bo.arg =
    ensureDefined: (argument, argumentName) ->
        if argument is undefined
            throw "Argument '#{argumentName}' must be defined."

    ensureFunction: (argument, argumentName) ->
       if _.isFunction argument is false
            throw "Argument '#{argumentName}' must be a function. '#{argument}' was passed."
            
    ensureString: (argument, argumentName) ->
        if typeof argument isnt 'string'
            throw "Argument '#{argumentName}' must be a string. '#{argument}' was passed."
            
    ensureNumber: (argument, argumentName) ->
        if typeof argument isnt 'number'
            throw "Argument '#{argumentName}' must be a number. '#{argument}' was passed."

window.bo.exportSymbol = (path, object) ->
    tokens = path.split '.'
    target = window

    target = target[token] || (target[token] = {}) for token in tokens[0..tokens.length-2]
    target[tokens[tokens.length - 1]] = object

if not window.console
    window.console =
        log: -> 

if not Array::sum
    Array::sum = ->
        sum = 0
        sum += e for e in @
        sum

if not String::startsWith
    String::startsWith = (value) ->
        @lastIndexOf(value, 0) is 0

if not String::endsWith
    String::endsWith = (suffix) ->
        (@indexOf suffix, (@length - suffix.length)) != -1
