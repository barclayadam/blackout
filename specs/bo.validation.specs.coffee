#reference '../../js/blackout/bo.validation.coffee'

describe 'Validation:', ->
    describe 'When validating', ->
        it 'should throw an exception if a validator is specified that does not exist', ->
            # Arrange
            model = bo.validatableModel { myProperty: 'myValue' }
            bo.validatableModel model, { myProperty: { myNonExistentValidator: true } } 

            # Act
            validate = -> model.validate()

            # Assert
            expect(validate).toThrow '\'myNonExistentValidator\' is not a validator. Must be defined as method on bo.validation.rules'

        it 'should validate properties by executing method attached to bo.validate', ->
            # Arrange
            requiredSpy = @spy bo.validation.rules.required, "validator"
            model = { myProperty: 'myValue' }
            bo.validatableModel model, { myProperty: { required: true } } 

            # Act
            model.validate()

            # Assert
            expect(requiredSpy).toHaveBeenCalled()
            expect(requiredSpy).toHaveBeenCalledWith 'myValue', model, true

        it 'should validate arrays with elements with validation rules as bracketed error keys', ->
            # Arrange
            ArrayItemType = ->
                model =
                    arrayProperty: undefined                        

                bo.validatableModel model, { 'arrayProperty' : { required:  true } }                
            
            model = 
                myArray: [new ArrayItemType(), new ArrayItemType()]

            # Act
            validationErrors = bo.validation.validate model

            # Assert
            expect(validationErrors['myArray[0].arrayProperty']).toBeDefined()
            expect(validationErrors['myArray[1].arrayProperty']).toBeDefined()

        it 'should return an empty object if no validators fail', ->
            # Arrange
            bo.validation.rules.myCustomValidator = 
                validator: -> true

            model = { myProperty: 'myValue' }
            bo.validatableModel model, { myProperty: { myCustomValidator: true } } 

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors).toEqual {}

        it 'should return an empty object if model to validate is undefined', ->
            # Act
            validationErrors = bo.validation.validate undefined

            # Assert
            expect(validationErrors).toEqual {}

        it 'should revalidate an observable model when it changes if it was undefined when first validated', ->
            # Arrange
            model = { myProperty: undefined }
            bo.validatableModel model, { myProperty: { required: true } } 

            obs = ko.observable undefined

            validationErrors = bo.validation.validate obs
            expect(validationErrors).toEqual {}

            # Act
            obs model

            # Assert
            expect(model.modelErrors()['myProperty']).toBeDefined()

        it 'should unwrap an observable for validation', ->
            # Arrange
            model = { myProperty: undefined }
            bo.validatableModel model, { myProperty: { required: true } } 

            # Act
            validationErrors = bo.validation.validate ko.observable model

            # Assert
            expect(validationErrors['myProperty']).toBeDefined()

        it 'should return default failure message for property if validation fails and no message defined', ->
            # Arrange
            bo.validation.rules.myCustomValidator = 
                validator: -> false

            model = { myProperty: 'myValue' }
            bo.validatableModel model, { myProperty: { myCustomValidator: true } } 

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors).toEqual { 'myProperty': ['My Property validation failed']}

        it 'should return validators default error message when defined on bo.messages with no model validation message', ->
            # Arrange
            bo.validation.rules.myCustomValidator = 
                validator: -> false
                message: (propertyName, model, options) -> "#{propertyName} failed myCustomValidator validation"

            model = { myProperty: 'myValue' }
            bo.validatableModel model, { myProperty: { myCustomValidator: true } } 

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors).toEqual { 'myProperty': ['myProperty failed myCustomValidator validation']}

        it 'should return validation message for rule if message defined for rule explictly', ->
            # Arrange
            model = { myProperty: undefined }
            bo.validatableModel model, { myProperty: { required: true, requiredMessage: 'A custom validation message' } }

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors).toEqual { 'myProperty': ['A custom validation message']}

        it 'should validate simple properties', ->
            # Arrange
            model =
                myFirstProperty: undefined

            bo.validatableModel model, { 'myFirstProperty': { required: true } }

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors['myFirstProperty']).toBeDefined()

        it 'should set found errors to errors observable if it exists', ->
            # Arrange
            model =
                myFirstProperty: undefined

            bo.validatableModel model, { 'myFirstProperty': { required: true } }

            # Act
            validationErrors = model.validate()

            # Assert
            expect(model.modelErrors()['myFirstProperty']).toBeDefined()

        it 'should update errors property with new validation rules if validating an observable value', ->
            # Arrange
            model =
                myFirstProperty: ko.observable()

            bo.validatableModel model, { 'myFirstProperty' : { required: true } }
                                    
            model.validate()

            # Act
            model.myFirstProperty 12346

            # Assert
            expect(model.modelErrors()['myFirstProperty']).toBeUndefined()

        it 'should not validate properties with no validation rules', ->
            # Arrange
            model =
                myFirstProperty: undefined
                mySecondProperty: undefined

            bo.validatableModel model, { 'myFirstProperty': { required: true } }

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors['mySecondProperty']).toBeUndefined()

        it 'should validate observable properties', ->
            # Arrange
            model =
                myFirstProperty: ko.observable()

            bo.validatableModel model, { 'myFirstProperty': { required: true } }

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors['myFirstProperty']).toBeDefined()

        it 'should validate observable arrays with elements with validation rules as bracketed error keys', ->
            # Arrange
            ArrayItemType = ->
                model = 
                    arrayProperty: undefined
                
                bo.validatableModel model, { 'arrayProperty': { required: true } }

            model =
                myArray: ko.observableArray [new ArrayItemType(), new ArrayItemType()]

            bo.validatableModel model, {}

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors['myArray[0].arrayProperty']).toBeDefined()
            expect(validationErrors['myArray[1].arrayProperty']).toBeDefined()
            
        it 'should set found errors to errors property of each item of array, with parent key', ->
            # Arrange
            ArrayItemType = ->
                model = 
                    arrayProperty: undefined

                bo.validatableModel model, { 'arrayProperty': { required: true } }

            model = bo.validatableModel { myArray: [new ArrayItemType(), new ArrayItemType()] }

            # Act
            validationErrors = model.validate()

            # Assert
            expect(model.myArray[0].modelErrors()['arrayProperty']).toBeDefined()
            expect(model.myArray[1].modelErrors()['arrayProperty']).toBeDefined()

        it 'should validate child objects with validation rules as dot separated error keys', ->
            # Arrange
            model =
                myChildProperty: 
                    anotherProperty: undefined
                    modelValidationRules:
                        'anotherProperty':
                            required: true

            # Act
            validationErrors = bo.validation.validate model

            # Assert
            expect(validationErrors['myChildProperty.anotherProperty']).toBeDefined()

        it 'should set found errors to errors property if it exists on child object, with parent key', ->
            # Arrange
            model =
                myChildProperty:
                    anotherProperty: undefined

                    modelValidationRules:
                        'anotherProperty':
                            required: true

            # Act
            validationErrors = bo.validation.validate model

            # Assert
            expect(model.myChildProperty.modelErrors['anotherProperty']).toBeDefined()

        it 'should validate child observable objects with validation rules as dot separated error keys', ->
            # Arrange
            model =
                myChildProperty: ko.observable
                    anotherProperty: undefined
                    modelValidationRules:
                        'anotherProperty':
                            required: true

            # Act
            validationErrors = bo.validation.validate model

            # Assert
            expect(validationErrors['myChildProperty.anotherProperty']).toBeDefined()

        it 'should validate nested child objects with validation rules as dot separated error keys', ->
            # Arrange
            model = bo.validatableModel
                myChildProperty:
                    myOtherChildProperty:
                        anotherProperty: undefined
                        modelValidationRules:
                            'anotherProperty':
                                required: true

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors['myChildProperty.myOtherChildProperty.anotherProperty']).toBeDefined()
            
    describe 'With an observable extended to be validatable', ->
        it 'returns a value which can be read', ->
            # Act
            observable = ko.observable(456).extend { validatable: { required: true } }
            
            # Assert
            expect(observable()).toEqual 456

        it 'returns a value which can be written', ->
            #Arrange
            observable = ko.observable(456).extend { validatable: { required: true } }
            
            # Act
            observable 123

            # Assert
            expect(observable()).toEqual 123

        it 'returns a value which can be read when using shortcut validatable function of observable', ->
            # Act
            observable = ko.observable(456).validatable { required: true }
            
            # Assert
            expect(observable()).toEqual 456

        it 'should include validation errors of property in returned errors list when validating model', ->
            # Arrange
            model = bo.validatableModel
                myFirstProperty: ko.observable().extend { validatable: { required: true } }

            # Act
            validationErrors = model.validate()

            # Assert
            expect(validationErrors['myFirstProperty']).toBeDefined()

        it 'should add validation errors to model errors property of containing model when validating model', ->
            # Arrange
            model = bo.validatableModel
                myFirstProperty: ko.observable().extend { validatable: { required: true } }

            # Act
            model.validate()

            # Assert
            expect(model.modelErrors()['myFirstProperty']).toBeDefined()

        it 'should set the errors observable of the validatable value when validating model', ->
            # Arrange
            model = bo.validatableModel
                myFirstProperty: ko.observable().extend { validatable: { required: true } }

            # Act
            model.validate()

            # Assert
            expect(model.myFirstProperty.errors()[0]).toEqual 'My First Property is required.'

        it 'should set the isValid observable of the validatable value to false when validation fails', ->
            # Arrange
            model = bo.validatableModel
                myFirstProperty: ko.observable().extend { validatable: { required: true } }

            # Act
            model.validate()

            # Assert
            expect(model.myFirstProperty.isValid()).toBe false

        it 'should update the errors property of validatable when value changes after initial validation', ->
            # Arrange
            model = bo.validatableModel
                myFirstProperty: ko.observable().extend { validatable: { required: true } }
                
            model.validate()
            expect(model.myFirstProperty.errors().length).toBe 1

            # Act
            model.myFirstProperty "A value to make me valid"

            # Assert
            expect(model.myFirstProperty.errors().length).toBe 0
        
    describe 'With a required validator', ->
        it 'should return true if property value is defined', ->
            # Act
            isValid = bo.validation.rules.required.validator 'my Value', {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is undefined', ->
            # Act
            isValid = bo.validation.rules.required.validator undefined, {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is null', ->
            # Act
            isValid = bo.validation.rules.required.validator null, {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is empty string', ->
            # Act
            isValid = bo.validation.rules.required.validator '', {}, true

            # Assert
            expect(isValid).toBe false

    describe 'With a regex validator', ->
        it 'should return true if property value is undefined', ->
            # Act
            isValid = bo.validation.rules.regex.validator undefined, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is null', ->
            # Act
            isValid = bo.validation.rules.regex.validator null, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is empty string', ->
            # Act
            isValid = bo.validation.rules.regex.validator '', {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value matches regular expression', ->
            # Act
            isValid = bo.validation.rules.regex.validator '01234', {}, /[0-9]+/

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value does not match regular expression', ->
            # Act
            isValid = bo.validation.rules.regex.validator 'abc', {}, /[0-9]+/

            # Assert
            expect(isValid).toBe false

    describe 'With a minLength validator', ->
        it 'should return true if property value is undefined', ->
            # Act
            isValid = bo.validation.rules.minLength.validator undefined, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is null', ->
            # Act
            isValid = bo.validation.rules.minLength.validator null, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is empty string', ->
            # Act
            isValid = bo.validation.rules.minLength.validator '', {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with required number of characters', ->
            # Act
            isValid = bo.validation.rules.minLength.validator '01', {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with more than required number of characters', ->
            # Act
            isValid = bo.validation.rules.minLength.validator '0123456', {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is string with too few characters', ->
            # Act
            isValid = bo.validation.rules.minLength.validator 'c', {}, 2

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a string', ->
            # Act
            isValid = bo.validation.rules.minLength.validator false, {}, [2, 4]

            # Assert
            expect(isValid).toBe false

    describe 'With a maxLength validator', ->
        it 'should return true if property value is undefined', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator undefined, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is null', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator null, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is empty string', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator '', {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with maximum number of characters allowed', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator '01', {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with less than maximum number of characters', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator '0', {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is string with too many characters', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator 'cfty', {}, 2

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a string', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator false, {}, [2, 4]

            # Assert
            expect(isValid).toBe false

    describe 'With a rangeLength validator', ->
        it 'should return true if property value is undefined', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator undefined, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is null', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator null, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is empty string', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator '', {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with minimum number of characters as defined by first element of options array', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator '12', {}, [2, 4]

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with maximum number of characters as defined by second element of options array', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator '1234', {}, [2, 4]

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with character count within minimum and maximum allowed', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator '123', {}, [2, 4]

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is string with too many characters', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator '12345', {}, [2, 4]

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is string with too few characters', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator '1', {}, [2, 4]

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a string', ->
            # Act
            isValid = bo.validation.rules.rangeLength.validator false, {}, [2, 4]

            # Assert
            expect(isValid).toBe false

    describe 'With a min validator', ->
        it 'should return true if property value is undefined', ->
            # Act
            isValid = bo.validation.rules.min.validator undefined, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is null', ->
            # Act
            isValid = bo.validation.rules.min.validator null, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is empty string', ->
            # Act
            isValid = bo.validation.rules.min.validator '', {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is equal to minimum option value', ->
            # Act
            isValid = bo.validation.rules.min.validator 56, {}, 56

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is greater than minimum option value', ->
            # Act
            isValid = bo.validation.rules.min.validator 456, {}, 56

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is less than minimum option value', ->
            # Act
            isValid = bo.validation.rules.min.validator 4, {}, 56

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a number', ->
            # Act
            isValid = bo.validation.rules.min.validator "Not a Number", {}, 5

            # Assert
            expect(isValid).toBe false

    describe 'With a max validator', ->
        it 'should return true if property value is undefined', ->
            # Act
            isValid = bo.validation.rules.max.validator undefined, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is null', ->
            # Act
            isValid = bo.validation.rules.max.validator null, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is empty string', ->
            # Act
            isValid = bo.validation.rules.max.validator '', {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is equal to maximum option value', ->
            # Act
            isValid = bo.validation.rules.max.validator 56, {}, 56

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is less than maximum option value', ->
            # Act
            isValid = bo.validation.rules.max.validator 34, {}, 56

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is greater than maximum option value', ->
            # Act
            isValid = bo.validation.rules.max.validator 346, {}, 56

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a number', ->
            # Act
            isValid = bo.validation.rules.max.validator "Not a Number", {}, 5

            # Assert
            expect(isValid).toBe false

    describe 'With a range validator', ->
        it 'should return true if property value is undefined', ->
            # Act
            isValid = bo.validation.rules.range.validator undefined, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is null', ->
            # Act
            isValid = bo.validation.rules.range.validator null, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is empty string', ->
            # Act
            isValid = bo.validation.rules.range.validator '', {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is minimum value as defined by first element of options array', ->
            # Act
            isValid = bo.validation.rules.range.validator 2, {}, [2, 65]

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is maximum value as defined by second element of options array', ->
            # Act
            isValid = bo.validation.rules.range.validator 65, {}, [2, 65]

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is within minimum and maximum allowed', ->
            # Act
            isValid = bo.validation.rules.range.validator 3, {}, [2, 4]

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is more than maximum', ->
            # Act
            isValid = bo.validation.rules.range.validator 5, {}, [2, 4]

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is less than minimum', ->
            # Act
            isValid = bo.validation.rules.range.validator 1, {}, [2, 4]

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a number', ->
            # Act
            isValid = bo.validation.rules.range.validator "Not a Number", {}, [2, 4]

            # Assert
            expect(isValid).toBe false
