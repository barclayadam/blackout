rules = bo.validation.rules

itShouldReturnTrueForEmptyValues = ((ruleName) ->
    it 'should return true if property value is undefined', ->
        # Act
        isValid = rules[ruleName].validator undefined, true, {}

        # Assert
        expect(isValid).toBe true

    it 'should return true if property value is null', ->
        # Act
        isValid = rules[ruleName].validator null, true, {}

        # Assert
        expect(isValid).toBe true

    it 'should return true if property value is empty string', ->
        # Act
        isValid = rules[ruleName].validator '', true, {}

        # Assert
        expect(isValid).toBe true

    it 'should return true if property value is all spaces', ->
        # Act
        isValid = rules[ruleName].validator '    ', true, {}

        # Assert
        expect(isValid).toBe true
)

describe 'Validation', ->
    describe 'With a required validator', ->
        it 'should return true if property value is defined', ->
            # Act
            isValid = rules.required.validator 'My Value', true, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is undefined', ->
            # Act
            isValid = rules.required.validator undefined, true, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is null', ->
            # Act
            isValid = rules.required.validator null, true, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is empty string', ->
            # Act
            isValid = rules.required.validator '', true, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is all spaces', ->
            # Act
            isValid = bo.validation.rules.required.validator '    ', true, {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @options = true
                @input = document.createElement 'input'

                rules.required.modifyElement @input, @options

            it 'should set aria-required attribute to true', ->
                expect(@input).toHaveAttr 'aria-required', 'true'

            it 'should set required attribute to true', ->
                expect(@input).toHaveAttr 'required', 'required'

    describe 'With a regex validator', ->
        itShouldReturnTrueForEmptyValues 'regex'

        it 'should return true if property value matches regular expression', ->
            # Act
            isValid = rules.regex.validator '01234', /[0-9]+/, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value does not match regular expression', ->
            # Act
            isValid = rules.regex.validator 'abc', /[0-9]+/, {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @regex = /[0-9]+/
                @input = document.createElement 'input'

                rules.regex.modifyElement @input, @regex

            it 'should set pattern attribute to regex', ->
                expect(@input).toHaveAttr 'pattern', @regex.toString()

    describe 'with a email validator', ->
        itShouldReturnTrueForEmptyValues 'email'

        defineTest = (expected, email) ->
            it "should return #{expected} if property value is '#{email}'", ->
                isValid = rules.email.validator email, true, {}

                expect(isValid).toBe expected

        defineTest true, "test@127.0.0.1"
        defineTest true, "test@example.com"
        defineTest true, "test@subdomain.domain.com"
        defineTest true, "test++example@subdomain.domain.com"
        
        defineTest false, "test@..."
        defineTest false, "test"
        defineTest false, "test@"

    describe 'with a postcode validator', ->
        itShouldReturnTrueForEmptyValues 'postcode'

        defineTest = (expected, postcode) ->
            it "should return #{expected} if property value is '#{postcode}'", ->
                isValid = rules.postcode.validator postcode, true, {}

                expect(isValid).toBe expected

        defineTest true, "PO112EF"
        defineTest true, "WN12 4FR"
        defineTest true, "GIR 0AA"
        defineTest true, "GIR0AA"
        defineTest true, "PO3 6JZ"
        defineTest true, "PO36JZ"

        defineTest false, "QWERTY"
        defineTest false, "PO12"
        defineTest false, "P012" # Numeric, not alpha

    describe 'With a minLength validator', ->
        itShouldReturnTrueForEmptyValues 'minLength'

        it 'should return true if property is string with required number of characters', ->
            # Act
            isValid = rules.minLength.validator '01', 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with more than required number of characters', ->
            # Act
            isValid = rules.minLength.validator '0123456', 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is string with too few characters', ->
            # Act
            isValid = rules.minLength.validator 'c', 2, {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if property is an array with required number of items', ->
            # Act
            isValid = rules.minLength.validator ['0','1'], 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is an array with more than required number of items', ->
            # Act
            isValid = rules.minLength.validator ['0','1'], 1

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is an array with too few items', ->
            # Act
            isValid = rules.minLength.validator ['c'], 2, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property does not have a length', ->
            # Act
            isValid = rules.minLength.validator false, [2, 4], {}

            # Assert
            expect(isValid).toBe false

    describe 'With an exactLength validator', ->
        itShouldReturnTrueForEmptyValues 'exactLength'

        it 'should return true if property is string with exact number of characters allowed', ->
            # Act
            isValid = rules.exactLength.validator '01', 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is string with less than the exact number of characters allowed', ->
            # Act
            isValid = rules.exactLength.validator '0', 2, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is string with greater than the exact number of characters allowed', ->
            #Act
            isValid = rules.exactLength.validator '012', 2, {}

            #Assert
            expect(isValid).toBe false

        it 'should return true if property is an array with exact number of items allowed', ->
            # Act
            isValid = rules.exactLength.validator ['0','1'], 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is an array with less than the exact number of items allowed', ->
            # Act
            isValid = rules.exactLength.validator ['0'], 2, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is an array with greater than the exact number of items allowed', ->
            #Act
            isValid = rules.exactLength.validator ['0','1','2'], 2, {}

            #Assert
            expect(isValid).toBe false

        it 'should return false if property does not have a length', ->
            # Act
            isValid = rules.exactLength.validator true, 3, {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @requiredLength = 8
                @input = document.createElement 'input'

                rules.exactLength.modifyElement @input, @requiredLength

            it 'should set maxLength attribute to exactLength option', ->
                expect(@input).toHaveAttr 'maxLength', @requiredLength.toString()

    describe 'With a maxLength validator', ->
        itShouldReturnTrueForEmptyValues 'maxLength'

        it 'should return true if property is string with maximum number of characters allowed', ->
            # Act
            isValid = rules.maxLength.validator '01', 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with less than maximum number of characters', ->
            # Act
            isValid = rules.maxLength.validator '0', 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is string with too many characters', ->
            # Act
            isValid = rules.maxLength.validator 'cfty', 2, {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if property is an array with maximum number of items allowed', ->
            # Act
            isValid = rules.maxLength.validator ['0','1'], 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is an array with less than maximum number of items', ->
            # Act
            isValid = rules.maxLength.validator ['0'], 2, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is an array with too many items', ->
            # Act
            isValid = rules.maxLength.validator ['c','f','t','y'], 2, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property does not have a length', ->
            # Act
            isValid = rules.maxLength.validator false, [2, 4], {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @maxLength = 8
                @input = document.createElement 'input'

                rules.maxLength.modifyElement @input, @maxLength

            it 'should set maxLength attribute to maxLength option', ->
                expect(@input).toHaveAttr 'maxLength', @maxLength.toString()

    describe 'With a rangeLength validator', ->
        itShouldReturnTrueForEmptyValues 'rangeLength'

        it 'should return true if property is string with minimum number of characters as defined by first element of options array', ->
            # Act
            isValid = rules.rangeLength.validator '12', [2, 4], {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with maximum number of characters as defined by second element of options array', ->
            # Act
            isValid = rules.rangeLength.validator '1234', [2, 4], {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is string with character count within minimum and maximum allowed', ->
            # Act
            isValid = rules.rangeLength.validator '123', [2, 4], {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is string with too many characters', ->
            # Act
            isValid = rules.rangeLength.validator '12345', [2, 4], {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is string with too few characters', ->
            # Act
            isValid = rules.rangeLength.validator '1', [2, 4], {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a string', ->
            # Act
            isValid = rules.rangeLength.validator false, [2, 4], {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @minLength = 6
                @maxLength = 8
                @input = document.createElement 'input'

                rules.rangeLength.modifyElement @input, [@minLength, @maxLength]

            it 'should set maxLength attribute to maxLength option', ->
                expect(@input).toHaveAttr 'maxLength', @maxLength.toString()

    describe 'With a min validator', ->
        itShouldReturnTrueForEmptyValues 'min'

        it 'should return true if property value is equal to minimum option value', ->
            # Act
            isValid = rules.min.validator 56, 56, {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is greater than minimum option value', ->
            # Act
            isValid = rules.min.validator 456, 56, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is less than minimum option value', ->
            # Act
            isValid = rules.min.validator 4, 56, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a number', ->
            # Act
            isValid = rules.min.validator "Not a Number", 5, {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @minValue = 6
                @input = document.createElement 'input'

                rules.min.modifyElement @input, @minValue

            it 'should set aria-valuemin attribute to minValue option', ->
                expect(@input).toHaveAttr 'aria-valuemin', @minValue.toString()

            it 'should set min attribute to minValue option', ->
                expect(@input).toHaveAttr 'min', @minValue.toString()

    describe 'With a moreThan validator', ->
        itShouldReturnTrueForEmptyValues 'moreThan'

        it 'should return false if property value is equal to minimum option value', ->
            # Act
            isValid = bo.validation.rules.moreThan.validator 56, 56, {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if property value is greater than minimum option value', ->
            # Act
            isValid = bo.validation.rules.moreThan.validator 456, 56, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is less than minimum option value', ->
            # Act
            isValid = bo.validation.rules.moreThan.validator 4, 56, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a number', ->
            # Act
            isValid = bo.validation.rules.moreThan.validator "Not a Number", 5, {}

            # Assert
            expect(isValid).toBe false

    describe 'With a max validator', ->
        itShouldReturnTrueForEmptyValues 'max'

        it 'should return true if property value is equal to maximum option value', ->
            # Act
            isValid = rules.max.validator 56, 56, {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is less than maximum option value', ->
            # Act
            isValid = rules.max.validator 34, 56, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is greater than maximum option value', ->
            # Act
            isValid = rules.max.validator 346, 56, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a number', ->
            # Act
            isValid = rules.max.validator "Not a Number", 5, {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @maxValue = 6
                @input = document.createElement 'input'

                rules.max.modifyElement @input, @maxValue

            it 'should set aria-valuemax attribute to maxValue option', ->
                expect(@input).toHaveAttr 'aria-valuemax', @maxValue.toString()

            it 'should set max attribute to maxValue option', ->
                expect(@input).toHaveAttr 'max', @maxValue.toString()


    describe 'With a lessThan validator', ->
        itShouldReturnTrueForEmptyValues 'lessThan'

        it 'should return false if property value is equal to maximum option value', ->
            # Act
            isValid = bo.validation.rules.lessThan.validator 56, 56, {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if property value is less than maximum option value', ->
            # Act
            isValid = bo.validation.rules.lessThan.validator 34, 56, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is greater than maximum option value', ->
            # Act
            isValid = bo.validation.rules.lessThan.validator 346, 56, {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a number', ->
            # Act
            isValid = bo.validation.rules.lessThan.validator "Not a Number", 5, {}

            # Assert
            expect(isValid).toBe false

    describe 'With a range validator', ->
        itShouldReturnTrueForEmptyValues 'range'

        it 'should return true if property is minimum value as defined by first element of options array', ->
            # Act
            isValid = rules.range.validator 2, [2, 65], {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is maximum value as defined by second element of options array', ->
            # Act
            isValid = rules.range.validator 65, [2, 65], {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property is within minimum and maximum allowed', ->
            # Act
            isValid = rules.range.validator 3, [2, 4], {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is more than maximum', ->
            # Act
            isValid = rules.range.validator 5, [2, 4], {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is less than minimum', ->
            # Act
            isValid = rules.range.validator 1, [2, 4], {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a number', ->
            # Act
            isValid = rules.range.validator "Not a Number", [2, 4], {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @minValue = 6
                @maxValue = 6
                @input = document.createElement 'input'

                rules.range.modifyElement @input, [@minValue, @maxValue]

            it 'should set aria-valuemin attribute to minValue option', ->
                expect(@input).toHaveAttr 'aria-valuemin', @minValue.toString()

            it 'should set min attribute to minValue option', ->
                expect(@input).toHaveAttr 'min', @minValue.toString()

            it 'should set aria-valuemax attribute to maxValue option', ->
                expect(@input).toHaveAttr 'aria-valuemax', @maxValue.toString()

            it 'should set max attribute to maxValue option', ->
                expect(@input).toHaveAttr 'max', @maxValue.toString()

    describe 'With a min date validator', ->
        itShouldReturnTrueForEmptyValues 'minDate'

        it 'should return true if property value is equal to minimum date value', ->
            # Act
            isValid = rules.minDate.validator new Date(2011, 1, 1), new Date(2011, 1, 1)

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is after than minimum date value', ->
            # Act
            isValid = rules.minDate.validator new Date(2010, 1, 1), new Date(2009, 1, 1)

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is before than minimum option value', ->
            # Act
            isValid = rules.minDate.validator new Date(2010, 1, 1), new Date(2011, 1, 1)

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date', ->
            # Act
            isValid = rules.minDate.validator "Not a Number", 5, {}

            # Assert
            expect(isValid).toBe false

    describe 'With a max date validator', ->
        itShouldReturnTrueForEmptyValues 'maxDate'

        it 'should return true if property value is equal to maximum date value', ->
            # Act
            isValid = rules.maxDate.validator new Date(2011, 1, 1), new Date(2011, 1, 1)

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is less than maximum date value', ->
            # Act
            isValid = rules.maxDate.validator new Date(2010, 1, 1), new Date(2011, 1, 1)

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is greater than maximum option value', ->
            # Act
            isValid = rules.maxDate.validator new Date(2011, 1, 1), new Date(2010, 1, 1)

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date', ->
            # Act
            isValid = rules.maxDate.validator "Not a Number", 5, {}

            # Assert
            expect(isValid).toBe false

    describe 'With a in the future validator', ->
        itShouldReturnTrueForEmptyValues 'inFuture'

        it 'should return true if property value is tomorrow', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.inFuture.validator tomorrow, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is today', ->
            # Act
            isValid = rules.inFuture.validator new Date(), "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is yesterday', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.inFuture.validator yesterday, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date', ->
            # Act
            isValid = rules.inFuture.validator "Not a Number", "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the future and temporal check type is DateTime', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.inFuture.validator tomorrow, "DateTime", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is in the past and temporal check type is DateTime', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.inFuture.validator yesterday, "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the future and temporal check type is DateTime', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = rules.inFuture.validator future, "DateTime", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the past and temporal check type is DateTime', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = rules.inFuture.validator past, "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date and temporal check type is DateTime', ->
            # Act
            isValid = rules.inFuture.validator "Not a Number", "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the future and temporal check type is Date', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.inFuture.validator tomorrow, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is in the past and temporal check type is Date', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.inFuture.validator yesterday, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is one second in the future and temporal check type is Date', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = rules.inFuture.validator future, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is one second in the past and temporal check type is Date', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = rules.inFuture.validator past, "Date", {}

            # Assert
            expect(isValid).toBe false

    describe 'With a in the past validator', ->
        itShouldReturnTrueForEmptyValues 'inPast'

        it 'should return false if property value is tomorrow', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.inPast.validator tomorrow, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property value is today', ->
            # Act
            isValid = rules.inPast.validator new Date(), "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if property value is yesterday', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.inPast.validator yesterday, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is not a date', ->
            # Act
            isValid = rules.inPast.validator "Not a Number", "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is in the future and temporal check type is DateTime', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.inPast.validator tomorrow, "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the past and temporal check type is DateTime', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.inPast.validator yesterday, "DateTime", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the future and temporal check type is DateTime', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = rules.inPast.validator future, "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the past and temporal check type is DateTime', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = rules.inPast.validator past, "DateTime", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is not a date and temporal check type is DateTime', ->
            # Act
            isValid = rules.inFuture.validator "Not a Number", "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is in the future and temporal check type is Date', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.inPast.validator tomorrow, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the past and temporal check type is Date', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.inPast.validator yesterday, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the future and temporal check type is Date', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = rules.inPast.validator future, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is one second in the past and temporal check type is Date', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = rules.inPast.validator past, "Date", {}

            # Assert
            expect(isValid).toBe false

    describe 'With a not in the past validator', ->
        itShouldReturnTrueForEmptyValues 'notInPast'

        it 'should return true if property value is tomorrow', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.notInPast.validator tomorrow, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is today', ->
            # Act
            isValid = rules.notInPast.validator new Date(), "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property value is yesterday', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.notInPast.validator yesterday, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date', ->
            # Act
            isValid = rules.notInPast.validator "Not a Number", "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the future and temporal check type is DateTime', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.notInPast.validator tomorrow, "DateTime", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is in the past and temporal check type is DateTime', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.notInPast.validator yesterday, "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the future and temporal check type is DateTime', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = rules.notInPast.validator future, "DateTime", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the past and temporal check type is DateTime', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = rules.notInPast.validator past, "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if property is not a date and temporal check type is DateTime', ->
            # Act
            isValid = rules.notInPast.validator "Not a Number", "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the future and temporal check type is Date', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.notInPast.validator tomorrow, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is in the past and temporal check type is Date', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.notInPast.validator yesterday, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the future and temporal check type is Date', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = rules.notInPast.validator future, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if date is one second in the past and temporal check type is Date', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = rules.notInPast.validator past, "Date", {}

            # Assert
            expect(isValid).toBe true

    describe 'With a not in future validator', ->
        itShouldReturnTrueForEmptyValues 'notInFuture'

        it 'should return false if property value is tomorrow', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.notInFuture.validator tomorrow, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if property value is today', ->
            # Act
            isValid = rules.notInFuture.validator new Date(), "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if property value is yesterday', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.notInFuture.validator yesterday, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is not a date', ->
            # Act
            isValid = rules.notInFuture.validator "Not a Number", "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is in the future and temporal check type is DateTime', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.notInFuture.validator tomorrow, "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the past and temporal check type is DateTime', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.notInFuture.validator yesterday, "DateTime", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if date is one second in the future and temporal check type is DateTime', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = rules.notInFuture.validator future, "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is one second in the past and temporal check type is DateTime', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = rules.notInFuture.validator past, "DateTime", {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if property is not a date and temporal check type is DateTime', ->
            # Act
            isValid = rules.notInFuture.validator "Not a Number", "DateTime", {}

            # Assert
            expect(isValid).toBe false

        it 'should return false if date is in the future and temporal check type is Date', ->
            # Arrange
            tomorrow = new Date()
            tomorrow.setDate tomorrow.getDate() + 1

            # Act
            isValid = rules.notInFuture.validator tomorrow, "Date", {}

            # Assert
            expect(isValid).toBe false

        it 'should return true if date is in the past and temporal check type is Date', ->
            # Arrange
            yesterday = new Date()
            yesterday.setDate yesterday.getDate() - 1

            # Act
            isValid = rules.notInFuture.validator yesterday, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if date is one second in the future and temporal check type is Date', ->
            # Arrange
            future = new Date()
            future.setSeconds future.getSeconds() + 1

            # Act
            isValid = rules.notInFuture.validator future, "Date", {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if date is one second in the past and temporal check type is Date', ->
            # Arrange
            past = new Date()
            past.setSeconds past.getSeconds() - 1

            # Act
            isValid = rules.notInFuture.validator past, "Date", {}

            # Assert
            expect(isValid).toBe true

    describe 'with an numeric validator', ->
        itShouldReturnTrueForEmptyValues 'numeric'

        it 'should return true if value is an integer', ->
            # Arrange
            value = '12'

            # Act
            isValid = rules.numeric.validator value, true, {}

            # Assert
            expect(isValid).toBe true

        it 'should return true if value is a double', ->
            # Arrange
            value = '1.2'

            # Act
            isValid = rules.numeric.validator value, true, {}

            # Assert
            expect(isValid).toBe true


        it 'should return false if value is not numeric', ->
            # Arrange
            value = 'numeric'

            # Act
            isValid = rules.numeric.validator value, true, {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @input = document.createElement 'input'

                rules.numeric.modifyElement @input, true

            it 'should set type attribute to numeric', ->
                expect(@input).toHaveAttr 'type', 'numeric'

    describe 'with an integer validator', ->
        itShouldReturnTrueForEmptyValues 'integer'

        it 'should return true if value is an integer', ->
            # Arrange
            value = '12'

            # Act
            isValid = bo.validation.rules.integer.validator value, true, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if value is a double', ->
            # Arrange
            value = '1.2'

            # Act
            isValid = bo.validation.rules.integer.validator value, true, {}

            # Assert
            expect(isValid).toBe false


        it 'should return false if value is not an integer', ->
            # Arrange
            value = 'numeric'

            # Act
            isValid = bo.validation.rules.integer.validator value, true, {}

            # Assert
            expect(isValid).toBe false

        describe 'with a modified input element', ->
            beforeEach ->
                @input = document.createElement 'input'

                rules.integer.modifyElement @input, true

            it 'should set type attribute to numeric', ->
                expect(@input).toHaveAttr 'type', 'numeric'

    describe 'with a requiredIf validator', ->
        it 'should return true if value does not trigger required validation and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value:  ko.observable('notTriggering'), equalsOneOf: ['triggering']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return true if value does not trigger required validation and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable('notTriggering'), equalsOneOf: ['triggering']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return true if value triggers required validation and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable('triggering'), equalsOneOf: ['triggering']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return false if value triggers required validation and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable('triggering'), equalsOneOf: ['triggering']  }, { }

            # Assert
            expect(isValid).toBe false

        it 'should return true if value triggers required validation from a list of possible options and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable('triggering'), equalsOneOf: ['triggering', 'trigger', 'anotherTrigger']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return false if value triggers required validation from a list of possible options and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable('triggering'), equalsOneOf: ['triggering', 'trigger', 'anotherTrigger']  }, { }
            
            # Assert
            expect(isValid).toBe false


        it 'should return true if value does not triggers required validation from a list of possible options and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable('notTriggering'), equalsOneOf: ['triggering', 'trigger', 'anotherTrigger']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return true if value does not trigger required validation from a list of possible options and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable('notTriggering'), equalsOneOf: ['triggering', 'trigger', 'anotherTrigger']  }, { }
            
            # Assert
            expect(isValid).toBe true

        it 'should return true if value triggers required validation when trigger is empty and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable(''), equalsOneOf: ['']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return false if value triggers required validation when trigger is empty and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIf.validator value, { value: ko.observable(''), equalsOneOf: ['']  }, { }
            
            # Assert
            expect(isValid).toBe false
        
        it 'should throw an error if a property or value field is not provided', ->
            # Arrange
            model = { conditionallyRequiredProperty: 'not empty' };

            # Act
            func = ->
                bo.validation.rules.requiredIf.validator model.conditionallyRequiredProperty, { equalsOneOf: ['']  }, model

            # Assert
            expect(func).toThrow 'You need to provide a value.'

        it 'should throw an error if no values are provided to compare with', ->
            # Arrange
            model = { conditionallyRequiredProperty: 'not empty', propertyToCheckAgainst: 'a value' };

            # Act
            func = ->
                bo.validation.rules.requiredIf.validator model.conditionallyRequiredProperty, {  property: 'propertyToCheckAgainst' }, model

            # Assert
            expect(func).toThrow 'You need to provide a list of items to check against.'

    describe 'with an equalTo validator', ->
        itShouldReturnTrueForEmptyValues 'equalTo'

        it 'should return true if value is equal', ->
            # Arrange
            value = '12'
            options = '12'

            # Act
            isValid = bo.validation.rules.equalTo.validator value, options

            # Assert
            expect(isValid).toBe true

        it 'should unwrap an observable model value', ->
            # Arrange
            value = '12'
            options = ko.observable value

            # Act
            isValid = bo.validation.rules.equalTo.validator value, options

            # Assert
            expect(isValid).toBe true

        it 'should return false if value is not equal', ->
            # Arrange
            value = '1.2'
            options = '12'

            # Act
            isValid = bo.validation.rules.equalTo.validator value, options

            # Assert
            expect(isValid).toBe false

    describe 'with a requiredIfNot validator', ->
        it 'should return true if value does not trigger required validation and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value:  ko.observable('notTriggering'), equalsOneOf: ['notTriggering']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return true if value does not trigger required validation and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('notTriggering'), equalsOneOf: ['notTriggering']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return true if value triggers required validation and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('triggering'), equalsOneOf: ['notTriggering']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return false if value triggers required validation and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('triggering'), equalsOneOf: ['notTriggering']  }, { }

            # Assert
            expect(isValid).toBe false

        it 'should return true if value triggers required validation from a list of possible options and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('triggering'), equalsOneOf: ['notTriggering', 'notTrigger', 'notAnotherTrigger']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return false if value triggers required validation from a list of possible options and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('triggering'), equalsOneOf: ['notTriggering', 'notTrigger', 'notAnotherTrigger']  }, { }
            
            # Assert
            expect(isValid).toBe false


        it 'should return true if value does not triggers required validation from a list of possible options and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('notTriggering'), equalsOneOf: ['notTriggering', 'notTrigger', 'notAnotherTrigger']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return true if value does not trigger required validation from a list of possible options and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('notTriggering'), equalsOneOf: ['notTriggering', 'notTrigger', 'notAnotherTrigger']  }, { }
            
            # Assert
            expect(isValid).toBe true

        it 'should return true if value triggers required validation when trigger is empty and value is not empty', ->
            # Arrange
            value = 'not empty'

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('trigger'), equalsOneOf: ['']  }, { }

            # Assert
            expect(isValid).toBe true

        it 'should return false if value triggers required validation when trigger is empty and value is empty', ->
            # Arrange
            value = undefined

            # Act
            isValid = bo.validation.rules.requiredIfNot.validator value, { value: ko.observable('trigger'), equalsOneOf: ['']  }, { }
            
            # Assert
            expect(isValid).toBe false
        
        it 'should throw an error if a property or value field is not provided', ->
            # Arrange
            model = { conditionallyRequiredProperty: 'not empty' };

            # Act
            func = ->
                bo.validation.rules.requiredIfNot.validator model.conditionallyRequiredProperty, { equalsOneOf: ['']  }, model

            # Assert
            expect(func).toThrow 'You need to provide a value.'

    describe 'with a custom validator', ->
        it 'should throw an error if the options parameter is undefined', ->
            # Act
            func = ->
                bo.validation.rules.custom.validator 'a value', undefined, {}

            # Assert
            expect(func).toThrow "Must pass a function to the 'custom' validator"

        it 'should throw an error if the options parameter is not a function', ->
            # Act
            func = ->
                bo.validation.rules.custom.validator 'a value', 'not a function', {}

            # Assert
            expect(func).toThrow "Must pass a function to the 'custom' validator"

        it 'should return true if validation function returns true', ->
            # Arrange
            validationFunction = ->
                true

            # Act
            isValid = bo.validation.rules.custom.validator 'a value', validationFunction, {}

            # Assert
            expect(isValid).toBe true

        it 'should return false if validation function returns false', ->
            # Arrange
            validationFunction = ->
                false

            # Act
            isValid = bo.validation.rules.custom.validator 'a value', validationFunction, {}

            # Assert
            expect(isValid).toBe false

        it 'should call custom validator with value parameter', ->
            # Arrange
            validationFunction = @spy()

            value = 'A Value'

            # Act
            bo.validation.rules.custom.validator value, validationFunction

            # Assert
            expect(validationFunction).toHaveBeenCalledWith value