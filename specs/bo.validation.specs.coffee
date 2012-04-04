#reference '../../js/blackout/bo.validation.coffee'

itShouldReturnTrueForEmptyValues = ((validator) ->
    it 'should return true if property value is undefined', ->
        # Act
        isValid = bo.validation.rules[validator].validator undefined, {}, true

        # Assert
        expect(isValid).toBe true

    it 'should return true if property value is null', ->
        # Act
        isValid = bo.validation.rules[validator].validator null, {}, true

        # Assert
        expect(isValid).toBe true

    it 'should return true if property value is empty string', ->
        # Act
        isValid = bo.validation.rules[validator].validator '', {}, true

        # Assert
        expect(isValid).toBe true
)
describe 'Validation:', ->
    describe 'When validating', ->
        it 'should throw an exception if a validator is specified that does not exist', ->
            # Arrange
            model = bo.validatableModel 
                myProperty: ko.observable('myValue').validatable { myNonExistentValidator: true }

            # Act
            validate = -> model.validate()

            # Assert
            expect(validate).toThrow '\'myNonExistentValidator\' is not a validator. Must be defined as method on bo.validation.rules'

        it 'should validate properties by executing method attached to bo.validate', ->
            # Arrange
            requiredSpy = @spy bo.validation.rules.required, "validator"
            model = bo.validatableModel 
                myProperty: ko.observable('myValue').validatable { required: true }

            # Act
            model.validate()

            # Assert
            expect(requiredSpy).toHaveBeenCalled()
            expect(requiredSpy).toHaveBeenCalledWith 'myValue', model, true

        it 'should return false if no validators fail', ->
            # Arrange
            bo.validation.rules.myCustomValidator = 
                validator: -> true

            model = bo.validatableModel 
                myProperty: ko.observable('myValue').validatable { myCustomValidator: true }

            # Act
            isValid = model.validate()

            # Assert
            expect(isValid).toEqual true

        it 'should return true if model to validate is undefined', ->
            # Act
            isValid = bo.validation.validate undefined

            # Assert
            expect(isValid).toEqual true

        it 'should revalidate an observable when it changes if it was undefined when first validated', ->
            # Arrange
            model = bo.validatableModel 
                myProperty: ko.observable(undefined).validatable { required: true }

            obs = ko.observable undefined

            bo.validation.validate obs

            # Act
            obs model

            # Assert
            expect(model.isValid()).toBe false

        it 'should unwrap an observable for validation', ->
            # Arrange
            model = bo.validatableModel 
                myProperty: ko.observable(undefined).validatable { required: true }

            # Act
            isValid = bo.validation.validate ko.observable model

            # Assert
            expect(isValid).toBe false

        it 'should set default failure message for property if validation fails and no message defined', ->
            # Arrange
            bo.validation.rules.myCustomValidator = 
                validator: -> false

            model = bo.validatableModel 
                myProperty: ko.observable('myValue').validatable { myCustomValidator: true }

            # Act
            model.validate()

            # Assert
            expect(model.myProperty.errors()[0]).toEqual 'My Property validation failed'

        it 'should return validators default error message when defined with no model validation message', ->
            # Arrange
            bo.validation.rules.myCustomValidator = 
                validator: -> false
                message: (propertyName, model, options) -> "#{propertyName} failed myCustomValidator validation"

            model = bo.validatableModel 
                myProperty: ko.observable('myValue').validatable { myCustomValidator: true }

            # Act
            model.validate()

            # Assert
            expect(model.myProperty.errors()[0]).toEqual 'myProperty failed myCustomValidator validation'

        it 'should return validation message for rule if message defined for rule explictly', ->
            # Arrange
            model = bo.validatableModel 
                myProperty: ko.observable(undefined).validatable { required: true, requiredMessage: 'A custom validation message' }

            # Act
            model.validate()

            # Assert
            expect(model.myProperty.errors()[0]).toEqual 'A custom validation message'

        it 'should validate properties that are validatable', ->
            # Arrange
            model = bo.validatableModel 
                myProperty: ko.observable(undefined).validatable { required: true }

            # Act
            model.validate()

            # Assert
            expect(model.myProperty.isValid()).toEqual false

        it 'should not validate properties with no validation rules', ->
            # Arrange
            model = bo.validatableModel
                myFirstProperty: ko.observable('A Value').validatable { required: true }
                mySecondProperty: ko.observable(undefined)

            # Act
            isValid = model.validate()

            # Assert
            expect(isValid).toBe true
            expect(model.isValid()).toBe true

        it 'should validate observable arrays', ->
            # Arrange
            ArrayItemType = ->
                arrayProperty: ko.observable(undefined).validatable { required: true }

            model = bo.validatableModel 
                myArray: ko.observableArray [new ArrayItemType(), new ArrayItemType()]

            # Act
            isValid = model.validate()

            # Assert
            expect(isValid).toEqual false
            expect(model.myArray()[0].arrayProperty.isValid()).toEqual false
            expect(model.myArray()[1].arrayProperty.isValid()).toEqual false

        it 'should validate child objects with validation rules', ->
            # Arrange
            model = bo.validatableModel
                myChildProperty: 
                    anotherProperty: ko.observable(undefined).validatable { required: true }

            # Act
            isValid = model.validate()

            # Assert
            expect(isValid).toEqual false
            expect(model.myChildProperty.anotherProperty.isValid()).toEqual false
            
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

        it 'should set the errors observable of the validatable value when validating', ->
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

    describe 'When adding server errors to validatable model', ->
        beforeEach ->
            @model = bo.validatableModel
                myProperty: ko.observable('My Value').validatable { required: true }

            @model.setServerErrors
                    '*': ['A global server error'],
                    'myProperty': ['myProperty server error']
                    'myUnknownProperty': ['myUnknownProperty server error']

        it 'should add known property errors onto a validatable property', ->
            expect(@model.myProperty.serverErrors()).toContain 'myProperty server error'

        it 'should not add errors of a known property to the model server errors', ->
            expect(@model.serverErrors()).toNotContain 'myProperty server error'

        it 'should add errors from the form property (*) to the model server errors', ->
            expect(@model.serverErrors()).toContain 'A global server error'

        it 'should add errors from unknown properties to the model server errors', ->
            expect(@model.serverErrors()).toContain 'myUnknownProperty server error'

    describe 'When clearing server errors', ->
        beforeEach ->
            @model = bo.validatableModel
                myProperty: ko.observable('My Value').validatable { required: true }

            # ensure server errors set
            @model.setServerErrors
                    '*': ['A global server error'],
                    'myProperty': ['myProperty server error']
                    'myUnknownProperty': ['myUnknownProperty server error']

            # Now clear
            @model.clearServerErrors()

        it 'should remove server errors from validatable properties', ->
            expect(@model.myProperty.serverErrors()).toBeAnEmptyArray()

        it 'should remove all model server errors', ->
            expect(@model.serverErrors()).toBeAnEmptyArray()

    describe 'When clearing server errors by setting an empty object', ->
        beforeEach ->
            @model = bo.validatableModel
                myProperty: ko.observable('My Value').validatable { required: true }

            # ensure server errors set
            @model.setServerErrors
                    '*': ['A global server error'],
                    'myProperty': ['myProperty server error']
                    'myUnknownProperty': ['myUnknownProperty server error']

            # Now clear
            @model.setServerErrors {}

        it 'should remove server errors from validatable properties', ->
            expect(@model.myProperty.serverErrors()).toBeAnEmptyArray()

        it 'should remove all model server errors', ->
            expect(@model.serverErrors()).toBeAnEmptyArray()
        
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
        itShouldReturnTrueForEmptyValues 'regex'

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
        itShouldReturnTrueForEmptyValues 'minLength'

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

        it 'should return true if property is an array with required number of items', ->
            # Act
            isValid = bo.validation.rules.minLength.validator ['0','1'], {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is an array with more than required number of items', ->
            # Act
            isValid = bo.validation.rules.minLength.validator ['0','1', '2'], {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is an array with too few items', ->
            # Act
            isValid = bo.validation.rules.minLength.validator ['c'], {}, 2

            # Assert
            expect(isValid).toBe false

        it 'should return false if property does not have a length', ->
            # Act
            isValid = bo.validation.rules.minLength.validator false, {}, [2, 4]

            # Assert
            expect(isValid).toBe false

    describe 'With an exactLength validator', ->
        itShouldReturnTrueForEmptyValues 'exactLength'

        it 'should return true if property is string with exact number of characters allowed', ->
            # Act
            isValid = bo.validation.rules.exactLength.validator '01', {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is string with less than the exact number of characters allowed', ->
            # Act
            isValid = bo.validation.rules.exactLength.validator '0', {}, 2

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is string with greater than the exact number of characters allowed', ->
            #Act
            isValid = bo.validation.rules.exactLength.validator '012', {}, 2

            #Assert
            expect(isValid).toBe false

        it 'should return true if property is an array with exact number of items allowed', ->
            # Act
            isValid = bo.validation.rules.exactLength.validator ['0','1'], {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is an array with less than the exact number of items allowed', ->
            # Act
            isValid = bo.validation.rules.exactLength.validator ['0'], {}, 2

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is an array with greater than the exact number of items allowed', ->
            #Act
            isValid = bo.validation.rules.exactLength.validator ['0','1','2'], {}, 2

            #Assert
            expect(isValid).toBe false

        it 'should return false if property does not have a length', ->
            # Act
            isValid = bo.validation.rules.exactLength.validator true, {}, 3

            # Assert
            expect(isValid).toBe false

    describe 'With a maxLength validator', ->
        itShouldReturnTrueForEmptyValues 'maxLength'

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

        it 'should return true if property is an array with maximum number of items allowed', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator ['0','1'], {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is an array with less than maximum number of items', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator ['0'], {}, 2

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is an array with too many items', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator ['c','f','t','y'], {}, 2

            # Assert
            expect(isValid).toBe false

        it 'should return false if property does not have a length', ->
            # Act
            isValid = bo.validation.rules.maxLength.validator false, {}, [2, 4]

            # Assert
            expect(isValid).toBe false

    describe 'With a rangeLength validator', ->
        itShouldReturnTrueForEmptyValues 'rangeLength'

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
        itShouldReturnTrueForEmptyValues 'min'

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
        itShouldReturnTrueForEmptyValues 'max'

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
        itShouldReturnTrueForEmptyValues 'range'

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

    describe 'With a min date validator', ->
        itShouldReturnTrueForEmptyValues 'minDate'

        it 'should return true if property value is equal to minimum date value', ->
            # Act
            isValid = bo.validation.rules.minDate.validator new Date(2011, 01, 01), {}, new Date(2011, 01, 01)

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is after than minimum date value', ->
            # Act
            isValid = bo.validation.rules.minDate.validator new Date(2010, 01, 01), {}, new Date(2009, 01, 01)

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is before than minimum option value', ->
            # Act
            isValid = bo.validation.rules.minDate.validator new Date(2010, 01, 01), {}, new Date(2011, 01, 01)

            # Assert
            expect(isValid).toBe false

        it 'should return true if string property value is equal to minimum date value', ->
            # Act
            isValid = bo.validation.rules.minDate.validator '01/01/2011', {}, '01/01/2011'

            # Assert
            expect(isValid).toBe true

        it 'should return true if string property value is after than minimum date value', ->
            # Act
            isValid = bo.validation.rules.minDate.validator '01/01/2011', {}, '01/01/2010'

            # Assert
            expect(isValid).toBe true

        it 'should return false if string property value is before than minimum option value', ->
            # Act
            isValid = bo.validation.rules.minDate.validator '01/01/2011', {}, '01/01/2012'

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date', ->
            # Act
            isValid = bo.validation.rules.minDate.validator "Not a Number", {}, 5

            # Assert
            expect(isValid).toBe false

    describe 'With a max date validator', ->
        itShouldReturnTrueForEmptyValues 'maxDate'

        it 'should return true if property value is equal to maximum date value', ->
            # Act
            isValid = bo.validation.rules.maxDate.validator new Date(2011, 01, 01), {}, new Date(2011, 01, 01)

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is less than maximum date value', ->
            # Act
            isValid = bo.validation.rules.maxDate.validator new Date(2010, 01, 01), {}, new Date(2011, 01, 01)

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is greater than maximum option value', ->
            # Act
            isValid = bo.validation.rules.maxDate.validator new Date(2011, 01, 01), {}, new Date(2010, 01, 01)

            # Assert
            expect(isValid).toBe false

        it 'should return true if string property value is equal to maximum date value', ->
            # Act
            isValid = bo.validation.rules.maxDate.validator '01/01/2011', {}, '01/01/2011'

            # Assert
            expect(isValid).toBe true

        it 'should return true if string property value is less than maximum date value', ->
            # Act
            isValid = bo.validation.rules.maxDate.validator '01/01/2010', {}, '01/01/2011'

            # Assert
            expect(isValid).toBe true

        it 'should return false if string property value is greater than maximum option value', ->
            # Act
            isValid = bo.validation.rules.maxDate.validator '01/01/2011', {}, '01/01/2010'

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date', ->
            # Act
            isValid = bo.validation.rules.maxDate.validator "Not a Number", {}, 5

            # Assert
            expect(isValid).toBe false

    describe 'With a in the future validator', ->
        itShouldReturnTrueForEmptyValues 'inFuture'

        it 'should return true if property value is tomorrow', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.inFuture.validator tomorrow, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is today', ->
            # Act
            isValid = bo.validation.rules.inFuture.validator new Date(), {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is yesterday', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.inFuture.validator yesterday, {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date', ->
            # Act
            isValid = bo.validation.rules.inFuture.validator "Not a Number", {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the future and temporal check type is DateTime', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.inFuture.validator tomorrow, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is in the past and temporal check type is DateTime', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.inFuture.validator yesterday, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the future and temporal check type is DateTime', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = bo.validation.rules.inFuture.validator future, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the past and temporal check type is DateTime', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = bo.validation.rules.inFuture.validator past, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date and temporal check type is DateTime', ->
            # Act
            isValid = bo.validation.rules.inFuture.validator "Not a Number", {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the future and temporal check type is Date', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.inFuture.validator tomorrow, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is in the past and temporal check type is Date', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.inFuture.validator yesterday, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is one second in the future and temporal check type is Date', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = bo.validation.rules.inFuture.validator future, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is one second in the past and temporal check type is Date', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = bo.validation.rules.inFuture.validator past, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe false

    describe 'With a in the past validator', ->
        itShouldReturnTrueForEmptyValues 'inPast'

        it 'should return false if property value is tomorrow', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.inPast.validator tomorrow, {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is today', ->
            # Act
            isValid = bo.validation.rules.inPast.validator new Date(), {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return true if property value is yesterday', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.inPast.validator yesterday, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is not a date', ->
            # Act
            isValid = bo.validation.rules.inPast.validator "Not a Number", {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is in the future and temporal check type is DateTime', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.inPast.validator tomorrow, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the past and temporal check type is DateTime', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.inPast.validator yesterday, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the future and temporal check type is DateTime', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = bo.validation.rules.inPast.validator future, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the past and temporal check type is DateTime', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = bo.validation.rules.inPast.validator past, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is not a date and temporal check type is DateTime', ->
            # Act
            isValid = bo.validation.rules.inFuture.validator "Not a Number", {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is in the future and temporal check type is Date', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.inPast.validator tomorrow, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the past and temporal check type is Date', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.inPast.validator yesterday, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the future and temporal check type is Date', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = bo.validation.rules.inPast.validator future, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is one second in the past and temporal check type is Date', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = bo.validation.rules.inPast.validator past, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe false

    describe 'With a not in the past validator', ->
        itShouldReturnTrueForEmptyValues 'notInPast'

        it 'should return true if property value is tomorrow', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.notInPast.validator tomorrow, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is today', ->
            # Act
            isValid = bo.validation.rules.notInPast.validator new Date(), {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is yesterday', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.notInPast.validator yesterday, {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date', ->
            # Act
            isValid = bo.validation.rules.notInPast.validator "Not a Number", {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the future and temporal check type is DateTime', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.notInPast.validator tomorrow, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is in the past and temporal check type is DateTime', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.notInPast.validator yesterday, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the future and temporal check type is DateTime', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = bo.validation.rules.notInPast.validator future, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the past and temporal check type is DateTime', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = bo.validation.rules.notInPast.validator past, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date and temporal check type is DateTime', ->
            # Act
            isValid = bo.validation.rules.notInPast.validator "Not a Number", {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the future and temporal check type is Date', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.notInPast.validator tomorrow, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is in the past and temporal check type is Date', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.notInPast.validator yesterday, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the future and temporal check type is Date', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = bo.validation.rules.notInPast.validator future, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe true

        it 'should return true if date is one second in the past and temporal check type is Date', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = bo.validation.rules.notInPast.validator past, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe true

    describe 'With a not in future validator', ->
        itShouldReturnTrueForEmptyValues 'notInFuture'

        it 'should return false if property value is tomorrow', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator tomorrow, {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return true if property value is today', ->
            # Act
            isValid = bo.validation.rules.notInFuture.validator new Date(), {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is yesterday', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator yesterday, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is not a date', ->
            # Act
            isValid = bo.validation.rules.notInFuture.validator "Not a Number", {}, true

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is in the future and temporal check type is DateTime', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator tomorrow, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the past and temporal check type is DateTime', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator yesterday, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the future and temporal check type is DateTime', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator future, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the past and temporal check type is DateTime', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator past, {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is not a date and temporal check type is DateTime', ->
            # Act
            isValid = bo.validation.rules.notInFuture.validator "Not a Number", {}, { type: "DateTime" }

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is in the future and temporal check type is Date', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator tomorrow, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the past and temporal check type is Date', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator yesterday, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe true

        it 'should return true if date is one second in the future and temporal check type is Date', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator future, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe true

        it 'should return true if date is one second in the past and temporal check type is Date', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = bo.validation.rules.notInFuture.validator past, {}, { type: "Date" }

            # Assert
            expect(isValid).toBe true

    describe 'with a date validator', ->
        itShouldReturnTrueForEmptyValues 'date'

        it 'should return true if value is parsable as a date', ->
            # Arrange
            value = '21/05/2012'

            # Act
            isValid = bo.validation.rules.date.validator value, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return false if the value is not parsable as a date', ->
            # Arrange
            value = '231/05/2012'

            # Act
            isValid = bo.validation.rules.date.validator value, {}, true

            # Assert
            expect(isValid).toBe false

    describe 'with an numeric validator', ->
        itShouldReturnTrueForEmptyValues 'numeric'

        it 'should return true if value is an integer', ->
            # Arrange
            value = '12'

            # Act
            isValid = bo.validation.rules.numeric.validator value, {}, true

            # Assert
            expect(isValid).toBe true

        it 'should return true if value is a double', ->
            # Arrange
            value = '1.2'

            # Act
            isValid = bo.validation.rules.numeric.validator value, {}, true

            # Assert
            expect(isValid).toBe true


        it 'should return false if value is not numeric', ->
            # Arrange
            value = 'numeric'

            # Act
            isValid = bo.validation.rules.numeric.validator value, {}, true

            # Assert
            expect(isValid).toBe false

    describe 'with an equalTo validator', ->
        itShouldReturnTrueForEmptyValues 'equalTo'

        it 'should return true if value is equal', ->
            # Arrange
            value = '12'

            # Act
            isValid = bo.validation.rules.equalTo.validator value, { property: value }, 'property'

            # Assert
            expect(isValid).toBe true

        it 'should return false if value is not equal', ->
            # Arrange
            value = '1.2'

            # Act
            isValid = bo.validation.rules.equalTo.validator value, { property: '12' }, 'property'

            # Assert
            expect(isValid).toBe false


        it 'should return false if other property does not exist', ->
            # Arrange
            value = 'numeric'

            # Act
            isValid = bo.validation.rules.equalTo.validator value, { }, 'property'

            # Assert
            expect(isValid).toBe false

        it 'should return true if value is equal to value in options', ->
            # Arrange
            value = '12'

            # Act
            isValid = bo.validation.rules.equalTo.validator value, { }, { value: '12' }

            # Assert
            expect(isValid).toBe true

        it 'should return true if value is equal to observable in options', ->
            # Arrange
            value = '12'

            # Act
            isValid = bo.validation.rules.equalTo.validator value, { }, { value: ko.observable('12') }

            # Assert
            expect(isValid).toBe true

