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
    else if bo.rules[ruleName]?.message?
        bo.rules[ruleName].message propertyName, model, ruleOptions
    else
        "#{bo.utils.fromCamelToTitleCase propertyName} validation failed" 

validateValue = (propertyName, propertyValue, propertyRules, model) ->
    errors = []
    propertyRules = propertyRules || propertyValue?.validationRules
    unwrappedPropertyValue = ko.utils.unwrapObservable propertyValue
    
    if propertyRules
        for ruleName, ruleOptions of propertyRules when !(ruleName.endsWith 'Message')
            if not bo.rules[ruleName]?
                throw new Error "'#{ruleName}' is not a validator. Must be defined as method on bo.validators"      

            isValid = bo.rules[ruleName].validator(unwrappedPropertyValue, model, ruleOptions)

            if not isValid
                errors.push getValidationFailureMessage propertyName, propertyValue, model, ruleName, ruleOptions 

    propertyValue.errors errors if propertyValue?.errors?
    errors

bo.validate = (modelToValidate, parentProperty = '') ->
    errors = {}

    # Use computed to allow observable properties to be automatically validated
    # on change, updating the errors property of the model being validated.
    ko.computed ->
        model = ko.utils.unwrapObservable modelToValidate

        if model?
            modelErrors = {}
            rules = model.modelValidationRules || {}
            
            for propertyName, propertyValue of model when not _(['modelErrors', 'modelValidationRules', 'validationRules', 'isValid', 'errors']).contains(propertyName)
                unwrappedPropertyValue = ko.utils.unwrapObservable propertyValue
                errorKey = createErrorKey propertyName, parentProperty

                valueValidationErrors = validateValue propertyName, propertyValue, rules[propertyName], model

                if valueValidationErrors.length > 0
                    errors[errorKey] = valueValidationErrors
                    modelErrors[propertyName] = valueValidationErrors

                if _.isArray unwrappedPropertyValue
                    for arrayItem, i in unwrappedPropertyValue
                        _.extend errors, bo.validate arrayItem, "#{errorKey}[#{i}]"
                else if jQuery.isPlainObject unwrappedPropertyValue
                    _.extend errors, bo.validate unwrappedPropertyValue, errorKey

            if ko.isWriteableObservable model.modelErrors
                model.modelErrors modelErrors
            else
                model.modelErrors = modelErrors

    errors

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

    model.validate = -> bo.validate model

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

bo.rules =
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
            (bo.rules.minLength.validator value, model, options[0]) and (bo.rules.maxLength.validator value, model, options[1])
    
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
            (bo.rules.min.validator value, model, options[0]) and (bo.rules.max.validator value, model, options[1])

        message: (propertyName, model, options) ->
            "#{bo.utils.fromCamelToTitleCase propertyName} must be between #{options[0]} and #{options[1]}."