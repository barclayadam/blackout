class bo.Uri
    encode = encodeURIComponent
    decode = decodeURIComponent

    standardPorts =
        http: 80
        https: 443

    queryStringVariable = (name, value) ->        
        t = encode(name)

        value = value.toString()

        if value.length > 0
            t += "=" + encode(value)  

        t

    objectToQuery = (variables) ->
        tmp = []

        for name, val of variables when val isnt null
            if _.isArray val
                for v in val when v isnt null
                    tmp.push queryStringVariable name, v 
            else
                tmp.push queryStringVariable name, val

        tmp.length and tmp.join "&"

    convertToType = (value) ->
        if not value?
            return undefined

        valueLower = value.toLowerCase()

        if valueLower is 'true' or valueLower is 'false'
            return value is 'true'

        asNumber = parseFloat value

        if not _.isNaN asNumber 
            return asNumber

        return value


    queryToObject = (qs) ->
        if not qs
            return {}

        qs = qs.replace /^[^?]*\?/, '' # Remove up to ?
        qs = qs.replace /&$/, ''   # Remove trailing &
        qs = qs.replace /\+/g, ' ' # Replace + with space

        query = {}

        for p in qs.split '&'
            split = p.split '='

            key = decode split[0] 
            value = convertToType decode split[1] 

            if query[key]
                # Convert existing to an array
                if not _.isArray query[key]                 
                    query[key] = [query[key]]

                query[key].push value

            else
                query[key] = value

        query

    constructor: (uri, options = { decode: true }) ->
        @variables = {}

        anchor = document.createElement 'a'
        anchor.href = uri

        @path = anchor.pathname
        
        if options.decode is true
            @path = decode @path

        if @path.charAt(0) != '/'
            @path = "/#{@path}"

        @fragment = anchor.hash?.substring(1)
        @query = anchor.search?.substring(1)
        @variables = queryToObject @query

        if uri.charAt(0) is '/' or uri.charAt(0) is '.'
            @isRelative = true
        else
            @isRelative = false

            @scheme = anchor.protocol
            @scheme = @scheme.substring 0, @scheme.length - 1

            @port = parseInt anchor.port, 10
            @host = anchor.hostname

            if standardPorts[@scheme] is @port
                @port = null

    clone: () ->
        new bo.Uri @toString()

    toString: ->
        s = ""
        q = objectToQuery @variables

        s =  @scheme + "://" if @scheme
        s += @host           if @host
        s += ":" + @port     if @port
        s += @path           if @path
        s += "?" + q         if q
        s += "#" + @fragment if @fragment
        s