describe 'Sorter', ->
    beforeEach ->
        @unsorted = [
            {
                id: 'ab',
                name: 'Adam Barclay',
                age: 22,
                dob: new Date 1988, 4, 14
            },

            {
                id: 'js',
                name: 'John Smith',
                age: 42,
                dob: new Date 1968, 5, 24
            },

            {
                id: 'abOlder',
                name: 'Adam Barclay',
                age: 30,
                dob: new Date 1980, 5, 24
            },

            {
                id: 'mj',
                name: 'Mary Jones',
                age: 30,
                dob: new Date 1980, 5, 24
            }
        ]

    describe 'no definition given', ->
        it 'should perform no sort', ->
            sorted = (new bo.Sorter()).sort @unsorted
            expect(_.pluck(sorted, 'id')).toEqual ['ab', 'js', 'abOlder', 'mj']

        it 'should have sort order as an observable', ->
            sorter = new bo.Sorter()
            expect(sorter.definition).toBeObservable()

    describe 'by string definition', ->
        describe 'single property sorting', ->
            it 'should sort by default ascending', ->
                sorted = (new bo.Sorter 'name').sort @unsorted
                expect(_.pluck(sorted, 'id')).toEqual ['ab', 'abOlder', 'js', 'mj']

            it 'should sort by descending if desc modifier specified', ->
                sorted = (new bo.Sorter 'name desc').sort @unsorted
                expect(_.pluck(sorted, 'id')).toEqual ['mj', 'js', 'ab', 'abOlder']

            it 'should sort by descending if descending modifier specified', ->
                sorted = (new bo.Sorter 'name descending').sort @unsorted
                expect(_.pluck(sorted, 'id')).toEqual ['mj', 'js', 'ab', 'abOlder']

            it 'should fully qualify with default ascending direction when converting to string', ->
                definition = (new bo.Sorter 'name').toString()
                expect(definition).toEqual 'name ascending'

            it 'should enable getting sort order by property name', ->
                sorter = new bo.Sorter 'name ascending'
                expect(sorter.getPropertySortOrder('name')).toEqual 'ascending'

            it 'should return undefined when asked for sort order of property not ordered', ->
                sorter = new bo.Sorter 'name ascending'
                expect(sorter.getPropertySortOrder('nonProperty')).toEqual undefined

        describe 'multiple property sorting', ->
            it 'should sort by default ascending', ->
                sorted = (new bo.Sorter 'name, age').sort @unsorted
                expect(_.pluck(sorted, 'id')).toEqual ['ab', 'abOlder', 'js', 'mj']

            it 'should sort by descending if desc modifier specified', ->
                sorted = (new bo.Sorter 'name, age desc').sort @unsorted
                expect(_.pluck(sorted, 'id')).toEqual ['abOlder', 'ab', 'js', 'mj']

            it 'should handle different directions in each property', ->
                sorted = (new bo.Sorter 'name descending, age asc').sort @unsorted
                expect(_.pluck(sorted, 'id')).toEqual ['mj', 'js', 'ab', 'abOlder']

            it 'should fully qualify with direction when converting to string', ->
                definition = (new bo.Sorter 'name desc, age ascending').toString()
                expect(definition).toEqual 'name descending, age ascending'

            it 'should enable getting sort order by property name', ->
                sorter = new bo.Sorter 'name desc, age ascending'

                expect(sorter.getPropertySortOrder('name')).toEqual 'descending'
                expect(sorter.getPropertySortOrder('age')).toEqual 'ascending'

            it 'should return undefined when asked for sort order of property not ordered', ->
                sorter = new bo.Sorter 'name ascending'
                expect(sorter.getPropertySortOrder('nonProperty')).toEqual undefined
