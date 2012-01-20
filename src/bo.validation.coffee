#reference "bo.coffee"

createErrorKey = (propertyName, parent) ->
    if parent != ''
        "#{parent}.#{propertyName}"
    else
        propertyName

hasValue = (value) ->
    value? and value != ''

emptyValue = (value) ->
    not hasValue value

getValidationFailureMessage = (propertyName, propertyValue, model, ruleName, ruleOptions) ->
    messagePropertyName = "#{ruleName}Message"

    if model.modelValidationRules?[propertyName]?[messagePropertyName]?
        model.modelValidationRules[propertyName][messagePropertyName]
    else if propertyValue?.validationRules?[messagePropertyName]?
        propertyValue.validationRules[messagePropertyName]
    else if bo.validation.rules[ruleName]?.message?
        bo.validation.rules[ruleName].message propertyName, model, ruleOptions
    else
        "#{bo.utils.fromCamelToTitleCase propertyName} validation failed" 

validateValue = (propertyName, propertyValue, propertyRules, model) ->
    errors = []
    propertyRules = propertyRules || propertyValue?.validationRules
    unwrappedPropertyValue = ko.utils.unwrapObservable propertyValue
    
    if propertyRules
        for ruleName, ruleOptions of propertyRules when !(ruleName.endsWith 'Message')
            if not bo.validation.rules[ruleName]?
                throw new Error "'#{ruleName}' is not a validator. Must be defined as method on bo.validation.rules"      

            isValid = bo.validation.rules[ruleName].validator(unwrappedPropertyValue, model, ruleOptions)

            if not isValid
                errors.push getValidationFailureMessage propertyName, propertyValue, model, ruleName, ruleOptions 

    propertyValue.errors errors if propertyValue?.errors?
    errors

bo.validation =
    modelProperties: ['modelErrors', 'modelValidationRules', 'validationRules', 'isValid', 'errors', 'serverErrors', 'allErrors', 'validate']

    validate: (modelToValidate, parentProperty = '') ->
        errors = {}

        # Use computed to allow observable properties to be automatically validated
        # on change, updating the errors property of the model being validated.
        ko.computed ->
            model = ko.utils.unwrapObservable modelToValidate

            if model?
                modelErrors = {}
                rules = model.modelValidationRules || {}
                
                for propertyName, propertyValue of model when not _(bo.validation.modelProperties).contains(propertyName)
                    unwrappedPropertyValue = ko.utils.unwrapObservable propertyValue
                    errorKey = createErrorKey propertyName, parentProperty

                    valueValidationErrors = validateValue propertyName, propertyValue, rules[propertyName], model

                    if valueValidationErrors.length > 0
                        errors[errorKey] = valueValidationErrors
                        modelErrors[propertyName] = valueValidationErrors

                    if _.isArray unwrappedPropertyValue
                        for arrayItem, i in unwrappedPropertyValue
                            _.extend errors, bo.validation.validate arrayItem, "#{errorKey}[#{i}]"
                    else if jQuery.isPlainObject unwrappedPropertyValue
                        _.extend errors, bo.validation.validate unwrappedPropertyValue, errorKey

                if ko.isWriteableObservable model.modelErrors
                    model.modelErrors modelErrors
                else
                    model.modelErrors = modelErrors

        errors
    
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

# Given a model and a set of (optional) model validation rules will add the necessary
# methods and observables to make the model validatable.
#
# This method adds the following methods & properties to the passed in model:
# 
#  * modelErrors -> An observable object that will contain any errors of the properties
#                   of this model (e.g. { 'myProperty' : ['Error 1', 'Error 2'] })
#  * isValid -> An observable that indicates whether this model is valid, based on the model
#               errors discussed previously.
#  * modelValidationRules -> The validation rules passed as the second argument, used
#                            as the rules for the properties of this model when validating.
#  * validate -> A function that can be executed to begin the validation process for this model.
#                Once a model has been validated it will automatically update its errors status
#                shuld any property that has been validated be an observable that changes it values.
bo.validatableModel = (model, modelValidationRules = {}) ->
    model.modelErrors = ko.observable {}
    model.isValid = ko.computed -> _.isEmpty model.modelErrors()
    model.modelValidationRules = modelValidationRules

    model.serverErrors = ko.observable {}

    model.allErrors = ko.computed ->
        _.extend {}, model.modelErrors(), model.serverErrors()

    model.validate = -> bo.validation.validate model

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
ko.extenders.validatable = (target, validationRules) ->
    target.errors = ko.observable []
    target.isValid = ko.computed -> target.errors().length is 0
    target.validationRules = validationRules

    target

ko.subscribable.fn.validatable = (validationRules) ->
    ko.extenders.validatable @, validationRules
    @
                        
ko.bindingHandlers.validated =
    options:
        inputValidClass: 'input-validation-valid'
        inputInvalidClass: 'input-validation-error'

        messageValidClass: 'field-validation-valid'
        messageInvalidClass: 'field-validation-error'

    init: (element, valueAccessor, allBindings, viewModel) ->
        value = valueAccessor()
        $element = jQuery element

        if value?.errors?
            $validationElement = jQuery('<span />').insertAfter $element
            ko.utils.domData.set element, 'validationElement', $validationElement

        if value?.validationRules?.required?
            $element.attr "aria-required", true

    update: (element, valueAccessor, allBindings, viewModel) ->
        $element = jQuery element
        $validationElement = ko.utils.domData.get element, 'validationElement'
        value = valueAccessor()
        
        if value?.errors?        
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