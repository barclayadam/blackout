#reference "bo.coffee"

# A class that represents a query string, a simple dictionary or key / value
# pairs that can be converted from and to a string representation of a
# query string.
class bo.QueryString
    # Creates a QueryString instance from the given string representation.
    @from: (qs) ->
        qs = qs.replace /&$/, ''   # Remove trailing &
        qs = qs.replace /\+/g, ' ' # Replace + with space

        query = new QueryString()				

        for p in qs.split '&'
            split = p.split '='

            queryKey = decodeURIComponent split[0] 
            queryValue = decodeURIComponent split[1] 

            query.set queryKey, queryValue

        query

    constructor: ->
        @values = {}

    set: (key, value) ->
        @values[key] = value

    # Given an object will copy all key <-> value pairs into this
    # query string.
    setAll: (values) ->
        @set key, value for own key, value of values when value?

    get: (key) ->
        @values[key]

    # Converts this QueryString into a string representation, including
    # the leading question mark used to delineate a URL and its
    # query string.
    toString: ->
        params = ("#{key}=#{value}" for key, value of @values)
        
        if params.length > 0
            "?" + params.join "&"
        else
            ""
        
bo.query = 
    get: (key) ->
        bo.query.current().get key

    current: ->
        bo.QueryString.from window.location.search.substring 1
