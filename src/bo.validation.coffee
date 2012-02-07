hasValue = (value) ->
    value? and value != ''

emptyValue = (value) ->
    not hasValue value

parseDate = (value) ->
    return value           if _.isDate value
    return new Date(value) if _.isString value

getMessageCreationFunction = (name, propertyRules, ruleName) ->
    messagePropertyName = "#{ruleName}Message"

    if propertyRules[messagePropertyName]?
        -> propertyRules[messagePropertyName]
    else if bo.validation.rules[ruleName]?.message?
        bo.validation.rules[ruleName].message
    else
        -> "#{bo.utils.fromCamelToTitleCase name} validation failed" 

validateValue = (propertyName, propertyValue, model) ->    
    errors = []

    if propertyValue?
        propertyRules = propertyValue.validationRules
        unwrappedPropertyValue = ko.utils.unwrapObservable propertyValue
        
        if propertyRules
            for ruleName, ruleOptions of propertyRules when !(ruleName.endsWith 'Message')
                if not bo.validation.rules[ruleName]?
                    throw new Error "'#{ruleName}' is not a validator. Must be defined as method on bo.validation.rules"      

                isValid = bo.validation.rules[ruleName].validator(unwrappedPropertyValue, model, ruleOptions)

                if not isValid
                    msgCreator = getMessageCreationFunction propertyName, propertyRules, ruleName
                    errors.push msgCreator propertyName, model, ruleOptions

    propertyValue.errors errors if propertyValue?.errors?
    
    errors.length is 0

propertiesToIgnore = ['errors', 'isValid', 'serverErrors', 'allErrors']

bo.validation =
    validate: (modelToValidate) ->
        valid = true

        # Use computed to allow observable properties to be automatically validated
        # on change.
        ko.computed ->
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
                "#{bo.utils.fromCamelToTitleCase propertyName} is required."

        regex:
            validator: (value, model, options) ->
                (emptyValue value) or (options.test value)

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} is invalid."

        exactLength: 
            validator: (value, model, options) ->
                (emptyValue value) or (value.length? and value.length == options)

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be exactly #{options} characters long."

        minLength: 
            validator: (value, model, options) ->
                (emptyValue value) or (value.length? and value.length >= options)

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be at least #{options} characters long."
        
        maxLength:
            validator: (value, model, options) ->
                (emptyValue value) or (value.length? and value.length <= options)
        
            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be no more than #{options} characters long."
        
        rangeLength:
            validator: (value, model, options) ->
                (bo.validation.rules.minLength.validator value, model, options[0]) and (bo.validation.rules.maxLength.validator value, model, options[1])
        
            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be between #{options[0]} and #{options[1]} characters long."

        min:
            validator: (value, model, options) ->
                (emptyValue value) or (value >= options)

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be equal to or greater than #{options}."

        max:
            validator: (value, model, options) ->
                (emptyValue value) or (value <= options)

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be equal to or less than #{options}."

        range:
            validator: (value, model, options) ->
                (bo.validation.rules.min.validator value, model, options[0]) and (bo.validation.rules.max.validator value, model, options[1])

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be between #{options[0]} and #{options[1]}."

        maxDate:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) <=  parseDate(options))

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be on or before #{options[0]}."

        minDate:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) >= parseDate(options))

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be on after #{options[0]}."

        inFuture:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) > new Date())

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be in the future."

        inPast:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) < new Date())

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must be in the past."

        notInPast:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) >= new Date())

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must not be in the past."

        notInFuture:
            validator: (value, model, options) ->
                (emptyValue value) or (parseDate(value) <= new Date())

            message: (propertyName, model, options) ->
                "#{bo.utils.fromCamelToTitleCase propertyName} must not be in the future."

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
    model.validate = -> bo.validation.validate model

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

ko.bindingHandlers.validationSummary =
    init: (element, valueAccessor) ->
        model = ko.utils.unwrapObservable valueAccessor()

    update: (element, valueAccessor) ->
        model = ko.utils.unwrapObservable valueAccessor()

        errorsToShow = [].concat model.allErrors()

        for own key, value of model
            if value.allErrors?
                if not value.__errorsShown__?
                    value.__errorsShown__ = ko.observable()

                if not value.__errorsShown__()
                    ko.utils.arrayPushAll errorsToShow, value.allErrors()

        element.innerHTML = errorsToShow.join '<br />'
                        
ko.bindingHandlers.validated =
    options:
        inputValidClass: 'input-validation-valid'
        inputInvalidClass: 'input-validation-error'

        messageValidClass: 'field-validation-valid'
        messageInvalidClass: 'field-validation-error'

    init: (element, valueAccessor, allBindings, viewModel) ->
        value = valueAccessor()
        $element = jQuery element

        if value?.allErrors?
            $validationElement = jQuery('<span />').insertAfter $element
            ko.utils.domData.set element, 'validationElement', $validationElement

        if value?.validationRules?.required?
            $element.attr "aria-required", true

            id = element.id
            jQuery("""label[for="#{id}"]""").addClass 'required'
            $element.addClass 'required'

    update: (element, valueAccessor, allBindings, viewModel) ->
        $element = jQuery element
        $validationElement = ko.utils.domData.get element, 'validationElement'
        value = valueAccessor()
        
        if value?.allErrors?        
            isEnabled = bo.utils.isElementEnabled allBindings
        
            errorMessages = value.allErrors()
            options = ko.bindingHandlers.validated.options

            isInvalid = isEnabled and errorMessages.length > 0
            isValid = not isInvalid

            $element.toggleClass options.inputValidClass, isValid
            $element.toggleClass options.inputInvalidClass, isInvalid

            $element.attr "aria-invalid", isInvalid
            
            $validationElement.toggleClass options.messageValidClass, isValid
            $validationElement.toggleClass options.messageInvalidClass, isInvalid

            $validationElement.html (if isValid then '' else errorMessages.join '<br />')