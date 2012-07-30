#reference "../../js/blackout/bo.bus.coffee"

describe 'Utils', ->
    describe 'When converting to title case', ->
        it 'should handle non-string values by calling toString', ->
            expect(bo.utils.toTitleCase undefined).toBeUndefined()

        it 'should uppercase the first character of subsequent words in the string', ->
            expect(bo.utils.toTitleCase 'myElephant').toEqual 'My Elephant'

        it 'should handle long strings', ->
            expect(bo.utils.toTitleCase 'thisIsMyVeryLargeVIPElephant').toEqual 'This Is My Very Large VIP Elephant'

        it 'should keep acronyms upper cased', ->
            expect(bo.utils.toTitleCase 'myVIPElephant').toEqual 'My VIP Elephant'

        it 'should split numbers from words', ->
            expect(bo.utils.toTitleCase 'AddressLine1').toEqual 'Address Line 1'

        it 'should handle multiple acronyms', ->
            expect(bo.utils.toTitleCase 'My PIN Number hasLeakedOMG').toEqual 'My PIN Number Has Leaked OMG'

        it 'should convert words as part of a larger sentence', ->
            expect(bo.utils.toTitleCase 'This is MY VeryLargeVIPElephant').toEqual 'This Is MY Very Large VIP Elephant'

    describe 'When converting to sentence case', ->
        it 'should return undefined for an undefined value being passed', ->
            expect(bo.utils.toSentenceCase undefined).toBeUndefined()

        it 'should handle non-string values by calling toString', ->
            expect(bo.utils.toSentenceCase true).toEqual 'True'

        it 'should uppercase the first character of the passed in string', ->
            expect(bo.utils.toSentenceCase 'MyElephant').toEqual 'My elephant'

        it 'should lowercase the first character of subsequent words in the string', ->
            expect(bo.utils.toSentenceCase 'myElephant').toEqual 'My elephant'

        it 'should handle long strings', ->
            expect(bo.utils.toSentenceCase 'thisIsMyVeryLargeVIPElephant').toEqual 'This is my very large VIP elephant'

        it 'should keep acronyms upper cased', ->
            expect(bo.utils.toSentenceCase 'myVIPElephant').toEqual 'My VIP elephant'

        it 'should handle multiple acronyms', ->
            expect(bo.utils.toSentenceCase 'My PIN Number hasLeakedOMG').toEqual 'My PIN number has leaked OMG'

        it 'should split numbers from words', ->
            expect(bo.utils.toSentenceCase 'AddressLine1').toEqual 'Address line 1'

        it 'should convert words as part of a larger sentence', ->
            expect(bo.utils.toSentenceCase 'This is MY VeryLargeVIPElephant').toEqual 'This is MY very large VIP elephant'

    describe 'When joining observables', ->
        it 'should set all observables to be the value of the first parameter', ->
            # Arrange
            obs1 = ko.observable 'My Value'
            obs2 = ko.observable 'My Other'

            # Act
            bo.utils.joinObservables obs1, obs2

            # Assert
            expect(obs2()).toEqual 'My Value'

        it 'should update other observable when master changes', ->
            # Arrange
            obs1 = ko.observable 'My Value'
            obs2 = ko.observable 'My Other'
            
            bo.utils.joinObservables obs1, obs2

            # Act
            obs1 'My New Value'

            # Assert
            expect(obs2()).toEqual 'My New Value'

        it 'should update master observable when second changes', ->
            # Arrange
            obs1 = ko.observable 'My Value'
            obs2 = ko.observable 'My Other'
            
            bo.utils.joinObservables obs1, obs2

            # Act
            obs2 'My New Value'

            # Assert
            expect(obs1()).toEqual 'My New Value'

        it 'should update all observables when master changes', ->
            # Arrange
            obs1 = ko.observable 'My Value'
            obs2 = ko.observable 'My Other'
            obs3 = ko.observable 'My Other'
            obs4 = ko.observable 'My Other'
            
            bo.utils.joinObservables obs1, obs2, obs3, obs4

            # Act
            obs1 'My New Value'

            # Assert
            expect(obs2()).toEqual 'My New Value'
            expect(obs3()).toEqual 'My New Value'
            expect(obs4()).toEqual 'My New Value'

        it 'should update other observable arrays when master changes', ->
            # Arrange
            obs1 = ko.observableArray []
            obs2 = ko.observableArray []
            
            bo.utils.joinObservables obs1, obs2

            # Act
            obs1.push 'My New Value'

            # Assert
            expect(obs2()[0]).toEqual 'My New Value'

    describe 'When converting from camel case to title case', ->
        it 'should uppercase the first character in the string', ->
            # Arrange
            rawValue = 'elephant'

            # Act
            converted = bo.utils.fromCamelToTitleCase rawValue

            # Assert
            expect(converted).toEqual 'Elephant'

        it 'should uppercase the first character of subsequent words in the string', ->
            # Arrange
            rawValue = 'myElephant'

            # Act
            converted = bo.utils.fromCamelToTitleCase rawValue

            # Assert
            expect(converted).toEqual 'My Elephant'

        it 'should keep acronyms upper cased', ->
            # Arrange
            rawValue = 'myVIPElephant'

            # Act
            converted = bo.utils.fromCamelToTitleCase rawValue

            # Assert
            expect(converted).toEqual 'My VIP Elephant'

    describe 'When converting to an observable', ->
        it 'should return an observable array if it is an array', ->
            # Arrange
            rawValue = ['a','b','c']

            # Act
            converted = bo.utils.asObservable rawValue

            # Assert
            expect(converted).toBeAnObservableArray()
            expect(converted()).toEqual rawValue

        it 'should return an observable if it is not an array', ->
            # Arrange
            rawValue = 'a'

            # Act
            converted = bo.utils.asObservable rawValue

            # Assert
            expect(converted).toBeObservable()
            expect(converted()).toEqual rawValue

        it 'should return an observable if it is undefined', ->
            # Arrange
            rawValue = null

            # Act
            converted = bo.utils.asObservable rawValue

            # Assert
            expect(converted).toBeObservable()
            expect(converted()).toEqual rawValue

        it 'should return the same observable if it is an observable', ->
            # Arrange
            rawValue = ko.observable 'a'

            # Act
            converted = bo.utils.asObservable rawValue

            # Assert
            expect(converted).toBeObservable()
            expect(converted).toEqual rawValue
