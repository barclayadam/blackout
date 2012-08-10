hasValue = (value) ->
    value? and value.toString().replace(/[ ]/g, '') != ''

emptyValue = (value) ->
    not hasValue value

parseDate = (value) ->
    return value if _.isDate value
    
    if _.isString value
        try
            return $.datepicker.parseDate 'dd/mm/yy', value 
        catch e
            undefined

withoutTime = (dateTime) ->
    new Date dateTime.getYear(), dateTime.getMonth(), dateTime.getDate() if dateTime?

today = () ->
    withoutTime new Date()

getMessageCreationFunction = (name, propertyRules, ruleName) ->
    messagePropertyName = "#{ruleName}Message"

    if propertyRules[messagePropertyName]?
        -> propertyRules[messagePropertyName]
    else if bo.validation.rules[ruleName]?.message?
        bo.validation.rules[ruleName].message
    else
        (propertyName) -> "#{propertyName} validation failed" 

formatErrorMessage = (msg) ->
    bo.utils.toSentenceCase msg

validateValue = (propertyName, propertyValue, model) ->    
    errors = []

    if propertyValue?
        propertyRules = propertyValue.validationRules
        propertyName = propertyRules.propertyName || propertyName
        unwrappedPropertyValue = ko.utils.unwrapObservable propertyValue
        
        if propertyRules
            for ruleName, ruleOptions of propertyRules when !(ruleName.endsWith 'Message') and ruleName != "propertyName"
                if not bo.validation.rules[ruleName]?
                    throw new Error "'#{ruleName}' is not a validator. Must be defined as method on bo.validation.rules"      

                isValid = bo.validation.rules[ruleName].validator unwrappedPropertyValue, model, ruleOptions

                if not isValid
                    msgCreator = getMessageCreationFunction propertyName, propertyRules, ruleName
                    errors.push formatErrorMessage msgCreator propertyName, model, ruleOptions

    propertyValue.errors errors if propertyValue?.errors?
    
    errors.length is 0

propertiesToIgnore = ['errors', 'isValid', 'serverErrors', 'allErrors']

bo.validation =
    addFormValidationAttribute: false,

    setupValidation: (modelToValidate) ->
        # Use computed to allow observable properties to be automatically validated
        # on change.
        ko.computed ->
            bo.validation.validate modelToValidate

    validate: (modelToValidate) ->
        valid = true
        model = ko.utils.unwrapObservable modelToValidate

        if model?                
            for propertyName, propertyValue of model when _(propertiesToIgnore).contains(propertyName) is false                    
                unwrappedPropertyValue = ko.utils.unwrapObservable propertyValue

                if propertyValue.validationRules?
                    valid = (validateValue propertyName, propertyValue, model) && valid

                if _.isArray unwrappedPropertyValue
                    for arrayItem in unwrappedPropertyValue
                        valid = (bo.validation.validate arrayItem) && valid
                else if jQuery.isPlainObject unwrappedPropertyValue
                    valid = (bo.validation.validate unwrappedPropertyValue) && valid

            if ko.isWriteableObservable model.isValid
                model.isValid valid

        valid
    
    rules:
        required: 
            validator: (value, model, options) ->
                hasValue value
            
            message: (propertyName, model, options) ->
                "#{propertyName} is required."

            modifyElement: (element) ->                
                element.setAttribute "aria-required", "true"
                element.setAttribute "required", "required" if bo.validation.addFormValidationAttribute
                ko.utils.toggleDomNodeCssClass element, 'required', true

                jQuery("""label[for="#{element.id}"]""").addClass 'required'

        regex:
            validator: (value, model, options) ->
                (emptyValue value) or (options.test value)

            message: (propertyName, model, options) ->
                "#{propertyName} is invalid."

            modifyElement: (element, options) ->                
                element.setAttribute "pattern", "" + options if bo.validation.addFormValidationAttribute

        exactLength: 
            validator: (value, model, options) ->
                (emptyValue value) or (value.length? and value.length == options)

            message: (propertyName, model, options) ->
                "#{propertyName} must be exactly #{options} characters long."

            modifyElement: (element, options) ->           
                element.setAttribute "maxLength", "" + options

        minLength: 
            validator: (value, model, options) ->
                (emptyValue value) or (value.length? and value.length >= options)

            message: (propertyName, model, options) ->
                "#{propertyName} must be at least #{options} characters long."
        
        maxLength:
            validator: (value, model, options) ->
                (emptyValue value) or (value.length? and value.length <= options)
        
            message: (propertyName, model, options) ->
                "#{propertyName} must be no more than #{options} characters long."

            modifyElement: (element, options) ->                
                element.setAttribute "maxLength", "" + options
        
        rangeLength:
            validator: (value, model, options) ->
                (bo.validation.rules.minLength.validator value, model, options[0]) and (bo.validation.rules.maxLength.validator value, model, options[1])
        
            message: (propertyName, model, options) ->
                "#{propertyName} must be between #{options[0]} and #{options[1]} characters long."

            modifyElement: (element, options) ->              
                element.setAttribute "maxLength", "" + options[1]

        min:
            validator: (value, model, options) ->
                (emptyValue value) or (value >= options)

            message: (propertyName, model, options) ->
                "#{propertyName} must be equal to or greater than #{options}."

            modifyElement: (element, options) ->                
                element.setAttribute "min", "" + options if bo.validation.addFormValidationAttribute

        moreThan:
            validator: (value, model, options) ->
                (emptyValue value) or (value > options)

            message: (propertyName, model, options) ->
                "#{propertyName} must be greater than #{options}."

            modifyElement: (element, options) ->                
                element.setAttribute "moreThan", "" + options if bo.validation.addFormValidationAttribute

        max:
            validator: (value, model, options) ->
                (emptyValue value) or (value <= options)

            message: (propertyName, model, options) ->
                "#{propertyName} must be equal to or less than #{options}."

            modifyElement: (element, options) ->                
                element.setAttribute "max", "" + options if bo.validation.addFormValidationAttribute

        lessThan:
            validator: (value, model, options) ->
                (emptyValue value) or (value < options)

            message: (propertyName, model, options) ->
                "#{propertyName} must be less than #{options}."

            modifyElement: (element, options) ->                
                element.setAttribute "lessThan", "" + options if bo.validation.addFormValidationAttribute

        range:
            validator: (value, model, options) ->
                (bo.validation.rules.min.validator value, model, options[0]) and (bo.validation.rules.max.validator value, model, options[1])

            message: (propertyName, model, options) ->
                "#{propertyName} must be between #{options[0]} and #{options[1]}."

            modifyElement: (element, options) ->                
                element.setAttribute "min", "" + options[0] if bo.validation.addFormValidationAttribute
                element.setAttribute "max", "" + options[1] if bo.validation.addFormValidationAttribute

        maxDate:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) <=  parseDate(options))

            message: (propertyName, model, options) ->
                "#{propertyName} must be on or before #{options[0]}."

        minDate:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) >= parseDate(options))

            message: (propertyName, model, options) ->
                "#{propertyName} must be after #{options[0]}."

        inFuture:
            validator: (value, model, options) ->
                if options is true or options.type is "Date"
                    (emptyValue value) or (withoutTime(parseDate(value)) > today())
                else
                    (emptyValue value) or (parseDate(value) > new Date())

            message: (propertyName, model, options) ->
                "#{propertyName} must be in the future."

        inPast:
            validator: (value, model, options) ->
                if options is true or options.type is "Date"
                    (emptyValue value) or (withoutTime(parseDate(value)) < today())
                else
                    (emptyValue value) or (parseDate(value) < new Date())

            message: (propertyName, model, options) ->
                "#{propertyName} must be in the past."

        notInPast:
            validator: (value, model, options) ->
                if options is true or options.type is "Date"
                    (emptyValue value) or (withoutTime(parseDate(value)) >= today())
                else
                    (emptyValue value) or (parseDate(value) >= new Date())

            message: (propertyName, model, options) ->
                "#{propertyName} must not be in the past."

        notInFuture:
            validator: (value, model, options) ->
                if options is true or options.type is "Date"
                    (emptyValue value) or (withoutTime(parseDate(value)) <= today())
                else
                    (emptyValue value) or (parseDate(value) <= new Date())

            message: (propertyName, model, options) ->
                "#{propertyName} must not be in the future."

        date:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) != undefined)

            message: (propertyName, model, options) ->
                "#{propertyName} must be a date."

        numeric:
            validator: (value, model, options) ->
                (emptyValue value) or (isFinite value)

            message: (propertyName, model, options) ->
                "#{propertyName} must be numeric."

        integer:
            validator: (value, model, options) ->
                (emptyValue value) or (/^[0-9]+$/.test value)

            message: (propertyName, model, options) ->
                "#{propertyName} must be a whole number."

        equalTo:
            validator: (value, model, options) ->
                if options.value?
                    (emptyValue value) or (value is ko.utils.unwrapObservable options.value)
                else    
                    (emptyValue value) or (value is ko.utils.unwrapObservable model[options])

            message: (propertyName, model, options) ->
                if options.value?
                    "#{propertyName} must be equal to #{options.value}."
                else    
                    "#{propertyName} must be equal to #{options}."

        requiredIf:
            validator: (value, model, options) ->
                if options.equalsOneOf is undefined
                    throw new Error "You need to provide a list of items to check against."

                if options.value is undefined and options.property is undefined
                    throw new Error "You need to provide either a property or a value."

                if options.property? and !model.hasOwnProperty(options.property)
                    throw new Error "The property #{options.property} cannot be found."

                valueToCheckAgainst = if options.value? then options.value else model[options.property]
                valueToCheckAgainst = (ko.utils.unwrapObservable valueToCheckAgainst) || null

                valueToCheckAgainstInList = _.any options.equalsOneOf, (v) -> (v || null) is valueToCheckAgainst

                if valueToCheckAgainstInList
                    hasValue value
                else
                    true
            message: (propertyName, model, options) ->
                "#{propertyName} is required."

        requiredIfNot:
            validator: (value, model, options) ->
                if options.equalsOneOf is undefined
                    throw new Error "You need to provide a list of items to check against."

                if options.value is undefined and options.property is undefined
                    throw new Error "You need to provide either a property or a value."

                if options.property? and !model.hasOwnProperty(options.property)
                    throw new Error "The property #{options.property} cannot be found."

                valueToCheckAgainst = if options.value? then options.value else model[options.property]
                valueToCheckAgainst = (ko.utils.unwrapObservable valueToCheckAgainst) || null

                valueToCheckAgainstNotInList = _.all options.equalsOneOf, (v) -> (v || null) isnt valueToCheckAgainst

                if valueToCheckAgainstNotInList
                    hasValue value
                else
                    true

            message: (propertyName, model, options) ->
                "#{propertyName} is required."

        custom:
            validator: (value, model, options) ->
                if options is undefined
                    throw new Error "Validation funcion cannot be undefined."

                if !_.isFunction options 
                    throw new Error "Validation function must be a function."

                options(value, model)

            message: (propertyName, model, options) ->
                "#{propertyName} is invalid."


# Given a model and a set of (optional) model validation rules will add the necessary
# methods and observables to make the model validatable.
bo.validatableModel = (model) ->
    # An array of errors that apply at the model level. This property is not updated as no model
    # level-validation logic currently exists, but is provided for symmetry with the validatable
    # observables so consumers that are only interested in errors messages and isValid state
    # do not need to care whether they are given a model or property.
    model.errors = ko.observable []

    # A boolean indicating whether or not this model is valid, only taking into account the
    # client-side validation errors that could be detected.
    model.isValid = ko.observable()

    # Contains an array of messages that indicate a validation failure for this
    # model, but only through server validation. The presence of server validation
    # errors does not make this model invalid.
    model.serverErrors = ko.observable []

    # A property that is present for consistency purposes with the `validatable`
    # extender, allowing the `validated` binding handler (and others) that deal with
    # validation errors to look only for a single property.
    #
    # This property simply delegates to the `serverErrors` property, being that a model
    # itself has no validation.
    model.allErrors = ko.computed ->
        [].concat(model.errors()).concat(model.serverErrors())

    # A function that can be executed to begin the validation process for this model.
    # 
    # Once a model has been validated it will automatically update its errors status
    # should any property that has been validated be an observable that changes it values.
    model.validate = _.once -> 
        bo.validation.setupValidation model

    # Sets any server validation errors, errors that could not be checked client
    # side but will stop a form being submitted / action being taken and therefore
    # the user must be informed.
    #
    # The `errors` argument is an object that contains property name to server errors
    # mappings, with all unknown property errors being flattened into a single
    # list within this model.
    model.setServerErrors = (errors) ->
        for own key, value of model
            if value?.validationRules?
                value.serverErrors errors[key] || []
                delete errors[key]

        model.serverErrors _.flatten _.values errors

    # Clears the server validation errors from this model.
    model.clearServerErrors = ->
        model.setServerErrors {}        

    model

# Makes an observable validatable, to be used in conjunction with a validatableModel
# and the bo.validate method.
#
# The observable will be extended with:
#  * errors -> An observable that will contain an array of the errors of the observable
#  * isValid -> An observable value that identifies the value of the observable as valid
#               according to its errors
#  * validationRules -> The rules passed as the options of this extender, used in the validation
#                       of this observable property.
ko.extenders.validatable = (target, validationRules = {}) ->
    target.errors = ko.observable []

    # A boolean indicating whether or not this observable is valid, only taking into account the
    # client-side validation errors that could be detected.
    target.isValid = ko.computed -> target.errors().length is 0
    target.validationRules = validationRules

    # Contains an array of messages that indicate a validation failure for this
    # property, but only through server validation. The presence of server validation
    # errors does not make this property invalid (see `isValid`).
    target.serverErrors = ko.observable []

    target.allErrors = ko.computed ->
        [].concat(target.errors()).concat(target.serverErrors())

    target

ko.subscribable.fn.validatable = (validationRules) ->
    ko.extenders.validatable @, validationRules
    @

bo.utils.addTemplate('validationSummaryTemplate',   ''' <ul class="validation-summary" data-bind="foreach: $data">
                                                            <li>
                                                                <span class="icon"></span>
                                                                <span class="text" data-bind="text: $data"></span>
                                                            </li>
                                                        </ul>''')

ko.bindingHandlers.validationSummary =
    init: (element, valueAccessor) ->
        model = ko.utils.unwrapObservable valueAccessor()

        { controlsDecendantBinding: true }

    update: (element, valueAccessor) ->
        model = ko.utils.unwrapObservable valueAccessor()

        errorsToShow = [].concat model.allErrors()

        for own key, value of model
            if value.allErrors?
                if not value.__errorsShown__?
                    value.__errorsShown__ = ko.observable()

                if not value.__errorsShown__()
                    ko.utils.arrayPushAll errorsToShow, value.allErrors()


        ko.renderTemplate('validationSummaryTemplate', errorsToShow, {}, element, 'replaceChildren');
                        
ko.bindingHandlers.validated =
    options:
        inputValidClass: 'validation-valid'
        inputInvalidClass: 'validation-error'

    init: (element, valueAccessor, allBindings, viewModel) ->
        value = valueAccessor()
        $element = jQuery element

        if ko.isObservable(value)
            if value.allErrors?
                $validationElement = jQuery('<span class="validation-text"><span class="icon" /><span class="text" /></span>').insertAfter($element)
                ko.utils.domData.set element, 'validationElement', $validationElement

            if not value.__errorsShown__?
                value.__errorsShown__ = ko.observable()

            value.__errorsShown__(true)

            if value.validationRules?
                for rule, options of value.validationRules
                    if bo.validation.rules[rule]?.modifyElement?
                        bo.validation.rules[rule].modifyElement element, options

    update: (element, valueAccessor, allBindings, viewModel) ->
        $element = jQuery element
        $label = jQuery("""label[for="#{element.id}"]""")
        $validationElement = ko.utils.domData.get element, 'validationElement'

        if $validationElement is undefined
            return

        value = valueAccessor()

        if not element._modifiedForValidation and value.validationRules?
            for rule, options of value.validationRules
                if bo.validation.rules[rule]?.modifyElement?
                    bo.validation.rules[rule].modifyElement element, options

            element._modifiedForValidation = true
        
        if value?.allErrors?        
            isEnabled = bo.utils.isElementEnabled allBindings
        
            errorMessages = value.allErrors()
            options = ko.bindingHandlers.validated.options

            isInvalid = isEnabled and errorMessages.length > 0
            isValid = not isInvalid

            toggleClasses = ($e) ->
                $e.toggleClass options.inputValidClass, isValid
                $e.toggleClass options.inputInvalidClass, isInvalid

                $e.attr "aria-invalid", isInvalid

            toggleClasses $element
            toggleClasses $label
            
            $validationElement.toggleClass options.inputValidClass, isValid
            $validationElement.toggleClass options.inputInvalidClass, isInvalid

            $validationElement.find('.text').html (if isValid then '' else errorMessages.join '<br />')
