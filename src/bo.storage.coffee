# Original from https://gist.github.com/350433
if typeof window.localStorage is "undefined" or typeof window.sessionStorage is "undefined"
    createCookie = (name, value, days) ->
        date = undefined
        expires = undefined

        if days
            date = new Date()
            date.setTime date.getTime() + (days * 24 * 60 * 60 * 1000)
            expires = "; expires=" + date.toGMTString()
        else
            expires = ""

        document.cookie = name + "=" + value + expires + "; path=/"

    readCookie = (name) ->
        nameEQ = name + "="

        ca = document.cookie.split ";"
        i = 0
        c = undefined

        while i < ca.length
            c = ca[i]
            c = c.substring(1, c.length) while c.charAt(0) is " "
            return c.substring(nameEQ.length, c.length) if c.indexOf(nameEQ) is 0
            i++

        null

    setData = (type, data) ->
        data = JSON.stringify data

        if type is "session"
            window.name = data
        else
            createCookie "localStorage", data, 365

    clearData = (type) ->
        if type is "session"
            window.name = ""
        else
            createCookie "localStorage", "", 365

    getData = (type) ->
        data = (if type is "session" then window.name else readCookie("localStorage"))
        
        if data then JSON.parse(data) else {}

    # Mimics the API of local/session storage to act as a polyfill in those browsers
    # that do not support the API.
    class Storage
        constructor: (@type) ->
            @length = 0
            @data = getData @type

        clear: ->
          @data = {}
          @length = 0
          clearData @type

        getItem: (key) ->
          if @data[key] is `undefined` then null else data[key]

        key: (i) ->
          ctr = 0

          for k of @data
            if ctr is i
              return k
            else
              ctr++
          null

        removeItem: (key) ->
          delete @data[key]

          @length--
          setData @type, data

        setItem: (key, value) ->
          @data[key] = value + ""
          @length++

          setData @type, data

    window.localStorage = new Storage("local") if typeof window.localStorage is "undefined"
    window.sessionStorage = new Storage("session") if typeof window.sessionStorage is "undefined"

ko.extenders.localStorage = (target, key) ->
    target window.localStorage.getItem key

    target.subscribe (newValue) ->
        window.localStorage.setItem key, newValue

    target

ko.extenders.sessionStorage = (target, key) ->
    target window.sessionStorage.getItem key

    target.subscribe (newValue) ->
        window.sessionStorage.setItem key, newValue

    target