validation = bo.validation = {}

getMessageCreator = (propertyRules, ruleName) ->
    propertyRules["#{ruleName}Message"] or
        bo.validation.rules[ruleName].message or
        "The field is invalid" 

# A function that is given a chance to format an error message
# that has been generated for any validation failures. This
# is provided to allow calling formatters such as `toSentenceCase`
# to produce better default messages.
#
# This function will take a single `string` parameter and should
# return a `string` to use as the error message.
validation.formatErrorMessage = (msg) -> msg

getErrors = (observableValue) ->    
    errors = []
    rules = observableValue.validationRules()

    # We only peek at the actual observable values as all subscriptions
    # are done manually in a validatable property's validate method, yet
    # this could be called as part of the model's validate method which
    # creates a computed around the whole model, causing multiple subscriptions.
    value = observableValue.peek()

    for ruleName, ruleOptions of rules 
        rule = bo.validation.rules[ruleName]

        if rule?
            isValid = rule.validator value, ruleOptions

            if not isValid
                msgCreator = getMessageCreator rules, ruleName

                if _.isFunction msgCreator
                    errors.push validation.formatErrorMessage msgCreator ruleOptions
                else 
                    errors.push validation.formatErrorMessage msgCreator

    errors

# Validates the specified 'model'.
#
# If the model has `validationRules` defined (e.g. a `validatable` observable) 
# will validate those values.
validateModel = (model) -> 
    valid = true  

    if model?
        # We have reached a property that has been marked as `validatable`
        if model.validate? and model.validationRules?
            model.validate()
            valid = model.isValid() && valid
          
        # Need to ensure that children are also validated, either
        # child properties (this is a 'model'), or an array (which
        # may also have its own validation rules).
        if ko.isObservable model 
            unwrapped = model.peek() 
        else 
            unwrapped = model

        if _.isObject unwrapped
            for own propName, propValue of unwrapped
                valid = (validateModel propValue) && valid

        if _.isArray unwrapped
            for item in unwrapped
                validateModel item

    valid

# Exposed as `bo.validation.mixin`
#
# Given a model will make it 'validatable', such that a call to
# the mixed-in `validate` method will validate the model and its
# children (properties) against a defined set of rules, rules that
# are defined at an observable property level using the `validated`
# observable extender.
#
# When a model is validated all child properties and arrays will be 
# navigated to check for validation rules, both observable and
# non-observable values, although only observable properties will
# have validation rules specified against them.
validation.mixin = (model) ->
    # Validates this model against the currently-defined set of
    # rules (against the child properties), setting up dependencies
    # on all propertes of this model to update the set of errors
    # and `isValid` state should any property change.
    #
    # The model of executing `validate` only once to set-up the
    # dependencies is to allow filling in a form completely
    # before checking validity to avoid errors being shown
    # immediately, but then allowing any errors detected to be removed
    # on property change immediately instead of having to attempt
    # a resubmit and a validate.
    model.validate = ->    
        # Only create a computed once, which will then keep
        # the `isValid` property up-to date whenever a value
        # of this model and its children changes.
        if not model.validated()
            ko.computed ->
                model.isValid validateModel model

            model.validated true

        # Whenever a model is explicitly validated the server errors
        # of the model will be reset, as it would not be possible to
        # determine validity of the model until going back to the server.
        model.serverErrors []

    # An observable that indicates whether this model has been validated,
    # set to `true` when the `validate` method of this method has been 
    # called at least once.
    model.validated = ko.observable false

    # An observable that indicates whether or not this model is
    # considered 'valid' on the client side, which is defined as having no
    # `client-side` validation errors.
    #
    # A model may have `serverErrors` that, as they can only be
    # checked server-side, are not considered when dealing with
    # the validitiy of a model as this value is used when determining
    # whether to even submit a form / command for processing by the
    # server.
    model.isValid = ko.observable()

    # An observable that will contain an array of error messages
    # that apply to the model as a whole but are not considered when
    # determining the `isValid` state of this form (e.g. it would not
    # stop the posting of a form to the server).
    model.serverErrors = ko.observable []

    # Sets any server validation errors, errors that could not be checked client
    # side but mean the action attempted failed. These server errors are not considered
    # when determining the `isValid` state of a form, but are instead for
    # informational purposes.
    #
    # The `errors` argument is an object that contains property name to server errors
    # mappings, with all unknown property errors being flattened into a single
    # list within this model.
    model.setServerErrors = (errors) ->
        for own key, value of model
            if value?.serverErrors?
                value.serverErrors _.flatten [errors[key]] || []
                delete errors[key]

        model.serverErrors _.flatten _.values errors

validation.newModel = (model = {}) ->
    validation.mixin model

    model

# Defines the set of validation rules that this observable must follow
# to be considered `valid`.
#
# The observable will be extended with:
#  * `errors` -> An observable that will contain an array of the errors of the observable
#  * `isValid` -> An observable value that identifies the value of the observable as valid
#                 according to its errors
#  * `validationRules` -> The rules passed as the options of this extender, used in the validation
#                         of this observable property.
ko.extenders.validationRules = (target, validationRules = {}) ->
    # We are adding rules to an already validatable property, just extend
    # its validation rules.
    if target.validationRules?
        target.validationRules _.extend target.validationRules(), validationRules
        return

    target.validationRules = ko.observable validationRules
    
    # Validates this property against the currently-defined set of
    # rules (against the child properties), setting up a dependency
    # that will update the `errors` and `isValid` property of this
    # observable on any value change.
    target.validate = ->
        target.validated true

    # An observable that indicates whether this property has been validated,
    # set to `true` when the `validate` method of this method has been 
    # called at least once.
    target.validated = ko.observable false

    target.errors = ko.observable []
    target.isValid = ko.observable true

    # An observable that will contain an array of error messages
    # that apply to this property but are not considered when
    # determining the `isValid` state of this property (e.g. it would not
    # stop the posting of a form to the server).
    target.serverErrors = ko.observable []

    validate = ->
        # When this value is changed the server errors will be removed, as
        # there would be no way to identify whether they were still accurate
        # or not until re-submitted, so for user-experience purposes these
        # errors are removed when a user modifies the value.
        target.serverErrors []

        target.errors getErrors target
        target.isValid target.errors().length is 0

    target.subscribe validate
    target.validationRules.subscribe validate

    validate()

    target

ko.subscribable.fn.addValidationRules = (validationRules) ->
    ko.extenders.validationRules @, validationRules