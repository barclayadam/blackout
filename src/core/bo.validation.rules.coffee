hasValue = (value) ->
    value? and (not value.replace or value.replace(/[ ]/g, '') isnt '')

emptyValue = (value) ->
    not hasValue value

parseDate = (value) ->
    if _.isDate value
        value

withoutTime = (dateTime) ->
    if dateTime?
        new Date dateTime.getYear(), dateTime.getMonth(), dateTime.getDate()

today = () ->
    withoutTime new Date()

labels = document.getElementsByTagName 'label'

getLabelFor = (element) ->
    _.find labels, (l) ->
        l.getAttribute('for') is element.id

rules =
    required: 
        validator: (value, options) ->
            hasValue value
        
        message: "This field is required"

        modifyElement: (element, options) ->                
            element.setAttribute "aria-required", "true"
            element.setAttribute "required", "required"
            
            label = getLabelFor element

            if label
                ko.utils.toggleDomNodeCssClass element, 'required', true

    regex:
        validator: (value, options) ->
            (emptyValue value) or (options.test value)

        message: "This field is invalid"

        modifyElement: (element, options) ->                
            element.setAttribute "pattern", "" + options

    numeric:
        validator: (value, options) ->
            (emptyValue value) or (isFinite value)

        message: (options) ->
            "This field must be numeric"

        modifyElement: (element, options) ->                
            element.setAttribute "type", 'numeric'   

    integer:
        validator: (value, options) ->
            (emptyValue value) or (/^[0-9]+$/.test value)

        message: "This field must be a whole number"

        modifyElement: (element, options) ->                
            element.setAttribute "type", 'numeric'           

    exactLength: 
        validator: (value, options) ->
            (emptyValue value) or (value.length? and value.length == options)

        message: (options) ->
            "This field must be exactly #{options} characters long"

        modifyElement: (element, options) ->        
            element.setAttribute "maxLength", options

    minLength: 
        validator: (value, options) ->
            (emptyValue value) or (value.length? and value.length >= options)

        message: (options) ->
            "This field must be at least #{options} characters long"
    
    maxLength:
        validator: (value, options) ->
            (emptyValue value) or (value.length? and value.length <= options)
    
        message: (options) ->
            "This field must be no more than #{options} characters long"

        modifyElement: (element, options) ->                
            element.setAttribute "maxLength", options
    
    rangeLength:
        validator: (value, options) ->
            (rules.minLength.validator value, options[0]) and (rules.maxLength.validator value, options[1])
    
        message: (options) ->
            "This field must be between #{options[0]} and #{options[1]} characters long"

        modifyElement: (element, options) ->
            element.setAttribute "maxLength", "" + options[1]

    min:
        validator: (value, options) ->
            (emptyValue value) or (value >= options)

        message: (options) ->
            "This field must be equal to or greater than #{options}"

        modifyElement: (element, options) ->                
            element.setAttribute "min", options             
            element.setAttribute "aria-valuemin", options

    moreThan:
        validator: (value, options) ->
            (emptyValue value) or (value > options)

        message: (options) ->
            "This field must be greater than #{options}."

    max:
        validator: (value, options) ->
            (emptyValue value) or (value <= options)

        message: (options) ->
            "This field must be equal to or less than #{options}"

        modifyElement: (element, options) ->                
            element.setAttribute "max", options             
            element.setAttribute "aria-valuemax", options

    lessThan:
        validator: (value, options) ->
            (emptyValue value) or (value < options)

        message: (options) ->
            "This field must be less than #{options}."

    range:
        validator: (value, options) ->
            (rules.min.validator value, options[0]) and (rules.max.validator value, options[1])

        message: (options) ->
            "This field must be between #{options[0]} and #{options[1]}"

        modifyElement: (element, options) -> 
            rules.min.modifyElement element, options[0]   
            rules.max.modifyElement element, options[1]            

    maxDate:
        validator: (value, options) ->
            (emptyValue value) or (parseDate(value) <=  parseDate(options))

        message: (options) ->
            "This field must be on or before #{options[0]}"

    minDate:
        validator: (value, options) ->
            (emptyValue value) or (parseDate(value) >= parseDate(options))

        message: (options) ->
            "This field must be on or after #{options[0]}"

    inFuture:
        validator: (value, options) ->
            if options is "Date"
                (emptyValue value) or (withoutTime(parseDate(value)) > today())
            else
                (emptyValue value) or (parseDate(value) > new Date())

        message: "This field must be in the future"

    inPast:
        validator: (value, options) ->
            if options is "Date"
                (emptyValue value) or (withoutTime(parseDate(value)) < today())
            else
                (emptyValue value) or (parseDate(value) < new Date())

        message: "This field must be in the past"

    notInPast:
        validator: (value, options) ->
            if options is "Date"
                (emptyValue value) or (withoutTime(parseDate(value)) >= today())
            else
                (emptyValue value) or (parseDate(value) >= new Date())

        message: "This field must not be in the past"

    notInFuture:
        validator: (value, options) ->
            if options is "Date"
                (emptyValue value) or (withoutTime(parseDate(value)) <= today())
            else
                (emptyValue value) or (parseDate(value) <= new Date())

        message: "This field must not be in the future"

    requiredIf:
        validator: (value, options) ->
            if options.equalsOneOf is undefined
                throw new Error "You need to provide a list of items to check against."

            if options.value is undefined
                throw new Error "You need to provide a value."

            valueToCheckAgainst = (ko.utils.unwrapObservable options.value) || null

            valueToCheckAgainstInList = _.any options.equalsOneOf, (v) -> (v || null) is valueToCheckAgainst

            if valueToCheckAgainstInList
                hasValue value
            else
                true

        message: "This field is required"

    requiredIfNot:
        validator: (value, options) ->
            if options.equalsOneOf is undefined
                throw new Error "You need to provide a list of items to check against."

            if options.value is undefined
                throw new Error "You need to provide a value."

            valueToCheckAgainst = (ko.utils.unwrapObservable options.value) || null

            valueToCheckAgainstNotInList = _.all options.equalsOneOf, (v) -> (v || null) isnt valueToCheckAgainst

            if valueToCheckAgainstNotInList
                hasValue value
            else
                true

        message: "This field is required"

    equalTo:
        validator: (value, options) ->
            (emptyValue value) or (value is ko.utils.unwrapObservable options)

        message: (options) ->
            "This field must be equal to #{options}."

    custom:
        validator: (value, options) ->
            if !_.isFunction options 
                throw new Error "Must pass a function to the 'custom' validator"

            options value

        message: "This field is invalid."

defineRegexValidator = (name, regex) ->
    rules[name] =
        validator: (value, options) ->
            rules.regex.validator value, regex

        message: "This field is an invalid #{name}"

        modifyElement: (element, options) ->                
            rules.regex.modifyElement element, regex

defineRegexValidator 'email', /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/i
defineRegexValidator 'postcode', /(GIR ?0AA)|((([A-Z][0-9]{1,2})|(([A-Z][A-HJ-Y][0-9]{1,2})|(([A-Z][0-9][A-Z])|([A-Z][A-HJ-Y][0-9]?[A-Z])))) ?[0-9][A-Z]{2})/i

bo.validation.rules = rules