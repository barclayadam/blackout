describe 'utils', ->
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


    describe 'When converting to an observable', ->
        it 'should return an observable array if it is an array', ->
            rawValue = ['a','b','c']

            # Act
            converted = bo.utils.asObservable rawValue

            expect(converted).toBeAnObservableArray()
            expect(converted()).toEqual rawValue

        it 'should return an observable if it is not an array', ->
            rawValue = 'a'

            converted = bo.utils.asObservable rawValue

            expect(converted).toBeObservable()
            expect(converted()).toEqual rawValue

        it 'should return an observable if it is undefined', ->
            rawValue = null

            converted = bo.utils.asObservable rawValue

            expect(converted).toBeObservable()
            expect(converted()).toEqual rawValue

        it 'should return the same observable if it is an observable', ->
            rawValue = ko.observable 'a'

            converted = bo.utils.asObservable rawValue

            expect(converted).toBeObservable()
            expect(converted).toEqual rawValue
