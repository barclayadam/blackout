#reference "../../js/blackout/bo.bus.coffee"

describe 'Utils', ->
    describe 'When converting to a CSS class', ->
        it 'should return undefined if given undefined parameter', ->
            # Act
            cssClass = bo.utils.toCssClass undefined

            # Assert
            expect(cssClass).toBeUndefined()

        it 'should replace spaces with dashes', ->
            # Act
            cssClass = bo.utils.toCssClass 'my class'

            # Assert
            expect(cssClass).toEqual 'my-class'

        it 'should lower case the value', ->
            # Act
            cssClass = bo.utils.toCssClass 'My Class'

            # Assert
            expect(cssClass).toEqual 'my-class'

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
