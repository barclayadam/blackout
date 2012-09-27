bo.utils =
    toTitleCase: (str) ->
        if str?
            convertWord = (match) ->
                # If 'word' matched is only an acronym perform no processing
                if match.toUpperCase() is match
                    match
                else
                    match = match.replace(/([a-z])([A-Z0-9])/g, (_, one, two) -> "#{one} #{two}") # insert a space between lower & upper / numbers
                    match = match.replace(/\b([A-Z]+)([A-Z])([a-z])/, (_, one, two, three) -> "#{one} #{two}#{three}") # space before last upper in a sequence followed by lower
                    match = match.replace(/^./, (s) -> s.toUpperCase()) # uppercase the first character

            str.toString()
                .replace(/\b[a-zA-Z0-9]+\b/g, convertWord)

    toSentenceCase: (str) ->
        if str?
            convertWord = (match) ->
                # If 'word' matched is only an acronym perform no processing
                if match.toUpperCase() is match
                    match
                else
                    match = match.replace(/([A-Z]{2,})([A-Z])$/g, (_, one, two) -> " #{one}#{two}") # Handle sentence ending with acronym
                    match = match.replace(/([A-Z]{2,})([A-Z])([^$])/g, (_, one, two, three) -> " #{one} #{two.toLowerCase()}#{three}") # Separate out acronyms first
                    match = match.replace(/([a-z])([A-Z0-9])/g, (_, one, two) -> "#{one} #{two.toLowerCase()}") # insert a space between lower & upper              
                    match = match.replace(/^./, (s) -> s.toLowerCase()) # lowercase the first character
                    match

            str = str.toString()                
            str = str.replace(/\b[a-zA-Z0-9]+\b/g, convertWord)
            str = str.replace(/^./, (s) -> s.toUpperCase()) # uppercase the first character
            str

    # Given a value will convert it to an observable, using the following rules:
    #
    # * If `value` is already an observable (`ko.isObservable`) return it directly
    # * If `value` is an array, return a `'ko.observableArray` initialised with the value
    # * For all other cases (including `undefined` or `null` values) return a `ko.observable` initialised with the value
    asObservable: (value) ->
        if ko.isObservable value then return value
        if _.isArray value then ko.observableArray value else ko.observable value