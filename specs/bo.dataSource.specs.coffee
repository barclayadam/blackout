describe 'DataSource', ->
    describe 'When a data source is created', ->
        beforeEach ->
            @loader = @spy()
            @dataSource = new bo.DataSource 
                provider: @loader

        it 'should have a pageSize observable property that is false', ->
            expect(@dataSource.isLoading).toBeObservable()
            expect(@dataSource.isLoading()).toBe false

        it 'should have a pageSize observable property', ->
            expect(@dataSource.pageSize).toBeObservable()

        it 'should have a pageNumber observable property', ->
            expect(@dataSource.pageNumber).toBeObservable()

        it 'should have a totalCount observable property', ->
            expect(@dataSource.totalCount).toBeObservable()

        it 'should have a pageCount observable property', ->
            expect(@dataSource.pageCount).toBeObservable()

        it 'should have a items observable array property that is empty', ->
            expect(@dataSource.items).toBeAnObservableArray()
            expect(@dataSource.items()).toBeAnEmptyArray()

        it 'should have a pageItems observable array property that is empty', ->
            expect(@dataSource.pageItems).toBeAnObservableArray()
            expect(@dataSource.pageItems()).toBeAnEmptyArray()

        it 'should not call the loader on construction', ->
            expect(@loader).toHaveNotBeenCalled()

    describe 'When a data source is loaded, with no paging', ->
        beforeEach ->
            @isLoadingDuringProvider = null

            @dataToReturn = [1, 4, 7, 8, 9, 13]
            @loader = @spy (o, callback, dataSource) => 
                @isLoadingDuringProvider = dataSource.isLoading()
                callback @dataToReturn
            @dataSource = new bo.DataSource 
                provider: @loader

            @dataSource.load()

        it 'should have a pagingEnabled property set to false', ->
            expect(@dataSource.pagingEnabled).toEqual false

        it 'should call the loader with an empty object as first parameter', ->
            expect(@loader).toHaveBeenCalledWith {}

        it 'should set the items observable to the value passed back from the loader', ->
            expect(@dataSource.items()).toEqual @dataToReturn

        it 'should set the pageItems observable to the value passed back from the loader', ->
            expect(@dataSource.pageItems()).toEqual @dataToReturn

        it 'should set the pageNumber observable to 1', ->
            expect(@dataSource.pageNumber()).toEqual 1

        it 'should set the pageCount observable to 1', ->
            expect(@dataSource.pageCount()).toEqual 1

        it 'should set the totalCount observable to the length of the loaded data', ->
            expect(@dataSource.totalCount()).toEqual @dataToReturn.length

        it 'should set the pageSize observable to the length of the loaded data', ->
            expect(@dataSource.pageSize()).toEqual @dataToReturn.length

        it 'should set isLoading to true during the provider callback', ->
            expect(@isLoadingDuringProvider).toEqual true

        it 'should set isLoading to false once data has been loaded', ->
            expect(@dataSource.isLoading()).toEqual false

    describe 'When a data source is loaded, with array provider', ->
        beforeEach ->
            @loadedData = [1, 4, 7, 8, 9, 13]
            @dataSource = new bo.DataSource 
                provider: @loadedData

        it 'should set the items observable to be the data supplied', ->
            expect(@dataSource.items()).toEqual @loadedData

        it 'should not throw exception when calling load', ->
            @dataSource.load() # Ensures does not throw exception

        it 'should set the pageItems observable to the data supplied', ->
            expect(@dataSource.pageItems()).toEqual @loadedData

        it 'should set the pageNumber observable to 1', ->
            expect(@dataSource.pageNumber()).toEqual 1

        it 'should set the pageCount observable to 1', ->
            expect(@dataSource.pageCount()).toEqual 1

        it 'should set the totalCount observable to the length of the loaded data', ->
            expect(@dataSource.totalCount()).toEqual @loadedData.length

        it 'should set the pageSize observable to the length of the loaded data', ->
            expect(@dataSource.pageSize()).toEqual @loadedData.length

    describe 'When a data source has a mapping function', ->
        beforeEach ->
            @dataSource = new bo.DataSource 
                provider: [1, 2, 3]
                map: (item) ->
                    { value: item }

        it 'should set the items observable to be the mapped data supplied', ->
            expect(@dataSource.items()).toEqual [
                { value: 1 },    
                { value: 2 },
                { value: 3 },
            ]

        it 'should set the pageItems observable to be the mapped data supplied', ->
            expect(@dataSource.pageItems()).toEqual [
                { value: 1 },    
                { value: 2 },
                { value: 3 },
            ]

        it 'should sort using the mapped property names', ->
            @dataSource.sortBy 'value descending'

            expect(@dataSource.pageItems()).toEqual [
                { value: 3 },    
                { value: 2 },
                { value: 1 },
            ]

    describe 'When a data source has a mapping function that returns undefined', ->
        beforeEach ->
            @dataSource = new bo.DataSource 
                provider: [1, 2, 3]
                map: (item) ->
                    { value: item } if (item % 2) is 0

        it 'should set ignore the undefined items when loading', ->
            expect(@dataSource.items()).toEqual [
                { value: 2 }
            ]

        it 'should set the pageItems observable to be the mapped data supplied', ->
            expect(@dataSource.pageItems()).toEqual [
                { value: 2 }
            ]

    describe 'When a data source is sorted ascending, with simple data set and no paging', ->
        beforeEach ->
            @dataSource = new bo.DataSource 
                provider: [1, 13, 7, 9, 8, 4]

            @dataSource.sort()

        it 'should set the sorting observable to ascending', ->
            expect(@dataSource.sorting()).toEqual 'ascending'

        it 'should set the items observable to be the sorted dataset', ->
            expect(@dataSource.items()).toEqual [1, 4, 7, 8, 9, 13]

    describe 'When a data source is sorted descending, with numeric data set and no paging', ->
        beforeEach ->
            @dataSource = new bo.DataSource 
                provider: [1, 13, 7, 9, 8, 4]

            @dataSource.sortDescending()

        it 'should set the sorting observable to descending', ->
            expect(@dataSource.sorting()).toEqual 'descending'

        it 'should set the items observable to be the sorted dataset', ->
            expect(@dataSource.items()).toEqual [13, 9, 8, 7, 4, 1]

    describe 'When a data source is sorted descending, with string data set and no paging', ->
        beforeEach ->
            @dataSource = new bo.DataSource 
                provider: ["a", "d", "b", "c"]

            @dataSource.sort()

        it 'should set the items observable to be the sorted dataset', ->
            expect(@dataSource.items()).toEqual ["a", "b", "c", "d"]

    describe 'When a data source is sorted by a single property, with complex data set and no paging', ->
        beforeEach ->
            @loadedData = [
                { myProperty: 1 }, 
                { myProperty: 13 }, 
                { myProperty: 7 }
            ]
            @dataSource = new bo.DataSource 
                provider: @loadedData

            @dataSource.sortBy 'myProperty'

        it 'should set the items observable to be the sorted dataset', ->
            expect(@dataSource.items()).toEqual [
                { myProperty: 1 }, 
                { myProperty: 7 }, 
                { myProperty: 13 }
            ]

        it 'should set the sorting observable to be a string representation of the ordering', ->
            expect(@dataSource.sorting()).toEqual 'myProperty ascending'

        it 'should indicate a columns ordering through getPropertySortOrder', ->
            expect(@dataSource.getPropertySortOrder('myProperty')).toEqual 'ascending'

    describe 'When a data source is sorted by multiple properties, with complex data set and no paging', ->
        beforeEach ->
            @loadedData = [
                { myProperty: 18, myOtherProperty: 1 },
                { myProperty: 7, myOtherProperty: 1 }, 
                { myProperty: 7, myOtherProperty: 4 }
            ]

            @dataSource = new bo.DataSource 
                provider: @loadedData

            @dataSource.sortBy 'myProperty, myOtherProperty'

        it 'should set the sorting observable to the normalised passed in properties', ->
            expect(@dataSource.sorting()).toEqual 'myProperty ascending, myOtherProperty ascending'

        it 'should set the items observable to be the sorted dataset, ascending default', ->
            expect(@dataSource.items()).toEqual [
                { myProperty: 7, myOtherProperty: 1 },
                { myProperty: 7, myOtherProperty: 4 },
                { myProperty: 18, myOtherProperty: 1 }
            ]

    describe 'When a data source is sorted, with client paging', ->
        beforeEach ->
            @dataSource = new bo.DataSource 
                provider: [1, 13, 7, 9, 8, 4]
                clientPaging: 5

            @dataSource.sort()

        it 'should have a pagingEnabled property set to true', ->
            expect(@dataSource.pagingEnabled).toEqual true

        it 'should set pageItems to ordered first page', ->
            expect(@dataSource.pageItems()).toEqual [1, 4, 7, 8, 9]

    describe 'When a data source is sorted, with server paging', ->
        beforeEach ->
            @sortedDataToReturn = [1, 4, 7, 8, 9, 13]
            @loader = @spy (o, callback) => callback 
                items: @sortedDataToReturn
                totalCount: @sortedDataToReturn.length

            @dataSource = new bo.DataSource 
                provider: @loader
                serverPaging: 5

            @dataSource.sort()
            @dataSource.load()

        it 'should have a pagingEnabled property set to true', ->
            expect(@dataSource.pagingEnabled).toEqual true

        it 'should pass the sorting value as a parameter to loader', ->
            expect(@dataSource.sorting()).toEqual 'ascending'

            expect(@loader).toHaveBeenCalledWith
                pageNumber: 1
                pageSize: 5
                orderBy: 'ascending' # Value of @dataSource.sorting()

        it 'should set the items observable to be the sorted dataset', ->
            expect(@dataSource.items()).toEqual [1, 4, 7, 8, 9, 13]

    describe 'When a data source is sorted after a load, with server paging', ->
        beforeEach ->
            @sortedDataToReturn = [1, 4, 7, 8, 9, 13]
            @loader = @spy (o, callback) => callback 
                items: @sortedDataToReturn
                totalCount: @sortedDataToReturn.length

            @dataSource = new bo.DataSource 
                provider: @loader
                serverPaging: 5

            @dataSource.load()

            @dataSource.sortBy 'aProperty ascending'

        it 'should pass the sorting value as a parameter to loader', ->
            expect(@loader).toHaveBeenCalledWith
                pageNumber: 1
                pageSize: 5
                orderBy: 'aProperty ascending'

    describe 'When a data source is loaded, with search parameters', ->
        beforeEach ->
            @dataToReturn = [1, 4, 7, 8, 9, 13]
            @loader = @spy (o, callback) => callback @dataToReturn
            @searchParameterObservable = ko.observable 10

            @dataSource = new bo.DataSource 
                searchParameters:
                    static: 5
                    observable: @searchParameterObservable
                provider: @loader

            @dataSource.load()

        it 'should call the loader with search parameters converted to plain values', ->
            expect(@loader).toHaveBeenCalledWith 
                static: 5
                observable: 10

    describe 'When search parameters change before an initial load', ->
        beforeEach ->
            # Arrange
            @dataToReturn = [1, 4, 7, 8, 9, 13]
            @loader = @spy (o, callback) => callback @dataToReturn
            @searchParameterObservable = ko.observable 10

            @dataSource = new bo.DataSource 
                searchParameters:
                    static: 5
                    observable: @searchParameterObservable
                provider: @loader

            # Act
            @searchParameterObservable 25

        it 'should not call the loader', ->
            expect(@loader).toHaveNotBeenCalled()

    describe 'When search parameters change after an initial load', ->
        beforeEach ->
            # Arrange
            @dataToReturn = [1, 4, 7, 8, 9, 13]
            @loader = @spy (o, callback) => callback @dataToReturn
            @searchParameterObservable = ko.observable 10

            @dataSource = new bo.DataSource 
                searchParameters:
                    static: 5
                    observable: @searchParameterObservable
                provider: @loader

            @dataSource.load()

            expect(@loader).toHaveBeenCalledOnce()

            # Act
            @searchParameterObservable 25

        it 'should call the loader with search parameters converted to plain values', ->
            expect(@loader).toHaveBeenCalledTwice() # Including initial load

            expect(@loader).toHaveBeenCalledWith                 
                static: 5
                observable: 25

        it 'should reset the pageNumber to 1', ->
            expect(@dataSource.pageNumber()).toEqual 1

    describe 'When search parameters change after an initial load, with server paging', ->
        beforeEach ->
            # Arrange
            @dataToReturn = [1, 4, 7, 8, 9, 13]
            @loader = @spy (o, callback) => callback @dataToReturn
            @searchParameterObservable = ko.observable 10

            @dataSource = new bo.DataSource 
                serverPaging: 5
                searchParameters:
                    static: 5
                    observable: @searchParameterObservable
                provider: @loader

            @dataSource.load()

            expect(@loader).toHaveBeenCalledOnce()

            # Act
            @searchParameterObservable 25

        it 'should call the loader with search parameters converted to plain values', ->
            expect(@loader).toHaveBeenCalledTwice() # Including initial load

            expect(@loader).toHaveBeenCalledWith
                static: 5
                observable: 25
                pageNumber: 1
                pageSize: 5

    describe 'When a data source is loaded, with client paging and remote data', ->
        beforeEach ->
            @dataToReturn = [1, 2, 3, 4, 5, 6, 7, 8]
            @loader = @spy (o, callback) => callback @dataToReturn
            @dataSource = new bo.DataSource 
                provider: @loader
                clientPaging: 5

            @dataSource.load()

        it 'should call the loader with an empty object as first parameter', ->
            expect(@loader).toHaveBeenCalledWith {}

        it 'should set the items observable to the value passed back from the loader', ->
            expect(@dataSource.items()).toEqual @dataToReturn

        it 'should set the pageItems observable to the first page of the return items', ->
            expect(@dataSource.pageItems()).toEqual [1, 2, 3, 4, 5]

        it 'should set the pageNumber observable to 1', ->
            expect(@dataSource.pageNumber()).toEqual 1

        it 'should set the pageCount observable to 2', ->
            expect(@dataSource.pageCount()).toEqual 2

        it 'should set the totalCount observable to the length of the loaded data', ->
            expect(@dataSource.totalCount()).toEqual @dataToReturn.length

        it 'should set the pageSize observable to the clientPaging size', ->
            expect(@dataSource.pageSize()).toEqual 5

    describe 'When a pageNumber is changed, after first load, with client paging and remote data', ->
        beforeEach ->
            # Arrange
            @dataToReturn = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            @loader = @spy (o, callback) => callback @dataToReturn
            @dataSource = new bo.DataSource 
                provider: @loader
                clientPaging: 5

            @dataSource.load()

            # Act
            @dataSource.pageNumber 2

        it 'should not call the loader again', ->
            expect(@loader).toHaveBeenCalledOnce() # The first load only

        it 'should set the pageItems observable to the page of items specified by page number', ->
            expect(@dataSource.pageItems()).toEqual [6, 7, 8, 9, 10]

        it 'should not reset the pageNumber that has been set', ->
            expect(@dataSource.pageNumber()).toEqual 2

        it 'should set the pageCount observable to 2', ->
            expect(@dataSource.pageCount()).toEqual 2

        it 'should set the totalCount observable to the length of the loaded data', ->
            expect(@dataSource.totalCount()).toEqual @dataToReturn.length

        it 'should set the pageSize observable to the clientPaging size', ->
            expect(@dataSource.pageSize()).toEqual 5

    describe 'When on the first page of multiple', ->
        beforeEach ->
            @dataToReturn = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            @loader = @spy (o, callback) => callback @dataToReturn
            @dataSource = new bo.DataSource 
                provider: @loader
                clientPaging: 5

            @dataSource.load()

        it 'should indicate on the first page through isFirstPage observable', ->
            expect(@dataSource.isFirstPage).toBeObservable()
            expect(@dataSource.isFirstPage()).toEqual true

        it 'should allow going to next page', ->
            # Act
            @dataSource.goToNextPage()

            # Assert
            expect(@dataSource.isFirstPage()).toEqual false
            expect(@dataSource.pageNumber()).toEqual 2

        it 'should not allow going to previous page', ->
            # Act
            @dataSource.goToPreviousPage()

            # Assert
            expect(@dataSource.isFirstPage()).toEqual true
            expect(@dataSource.pageNumber()).toEqual 1

    describe 'When on the last page of multiple', ->
        beforeEach ->
            @dataToReturn = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            @loader = @spy (o, callback) => callback @dataToReturn
            @dataSource = new bo.DataSource 
                provider: @loader
                clientPaging: 5

            @dataSource.load()
            @dataSource.pageNumber 2

        it 'should indicate on the last page through isLastPage observable', ->
            expect(@dataSource.isLastPage).toBeObservable()
            expect(@dataSource.isLastPage()).toEqual true

        it 'should not allow going to next page', ->
            # Act
            @dataSource.goToNextPage()

            # Assert
            expect(@dataSource.isLastPage()).toEqual true
            expect(@dataSource.pageNumber()).toEqual 2

        it 'should allow going to previous page', ->
            # Act
            @dataSource.goToPreviousPage()

            # Assert
            expect(@dataSource.isLastPage()).toEqual false
            expect(@dataSource.pageNumber()).toEqual 1

    describe 'When a data source is loaded, with server paging', ->
        beforeEach ->
            @allServerData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            @loader = @spy (o, callback) => 
                start = (o.pageNumber - 1) * o.pageSize
                end = start + o.pageSize

                callback 
                    items: @allServerData.slice start, end
                    totalCount: @allServerData.length

            @dataSource = new bo.DataSource 
                provider: @loader
                serverPaging: 5

            @dataSource.load()

        it 'should call the loader with pageSize and pageNumber parameters', ->
            expect(@loader).toHaveBeenCalledWith { pageSize: 5, pageNumber: 1}

        it 'should set the items observable to the value passed back from the loader', ->
            expect(@dataSource.items()).toEqual [1, 2, 3, 4, 5]

        it 'should set the pageItems observable to value passed back from the loader', ->
            expect(@dataSource.pageItems()).toEqual [1, 2, 3, 4, 5]

        it 'should set the pageNumber observable to 1', ->
            expect(@dataSource.pageNumber()).toEqual 1

        it 'should set the pageCount observable to 2', ->
            expect(@dataSource.pageCount()).toEqual 2

        it 'should set the totalCount observable to the value passed back from the loader', ->
            expect(@dataSource.totalCount()).toEqual @allServerData.length

        it 'should set the pageSize observable to the serverPaging size', ->
            expect(@dataSource.pageSize()).toEqual 5

    describe 'When a pageNumber is changed, after first load, with server paging', ->
        beforeEach ->
            # Arrange
            @allServerData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            @loader = @spy (o, callback) => 
                start = (o.pageNumber - 1) * o.pageSize
                end = start + o.pageSize

                callback 
                    items: @allServerData.slice start, end
                    totalCount: @allServerData.length

            @dataSource = new bo.DataSource 
                provider: @loader
                serverPaging: 5

            @dataSource.load()
            expect(@loader).toHaveBeenCalledOnce()

            # Act
            @dataSource.pageNumber 2

        it 'should call the loader again', ->
            expect(@loader).toHaveBeenCalledTwice()

        it 'should set the pageItems observable to the page of items specified by page number', ->
            expect(@dataSource.pageItems()).toEqual [6, 7, 8, 9, 10]

        it 'should not reset the pageNumber that has been set', ->
            expect(@dataSource.pageNumber()).toEqual 2

        it 'should set the pageCount observable to 2', ->
            expect(@dataSource.pageCount()).toEqual 2

        it 'should set the totalCount observable to the value passed back from the loader', ->
            expect(@dataSource.totalCount()).toEqual @allServerData.length

        it 'should set the pageSize observable to the serverPaging size', ->
            expect(@dataSource.pageSize()).toEqual 5

    describe 'When a data source is loaded, with client and server paging', ->
        beforeEach ->
            @allServerData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
            @loader = @spy (o, callback) => 
                start = (o.pageNumber - 1) * o.pageSize
                end = start + o.pageSize

                callback 
                    items: @allServerData.slice start, end
                    totalCount: @allServerData.length

            @dataSource = new bo.DataSource 
                provider: @loader
                clientPaging: 5
                serverPaging: 10

            @dataSource.load()

        it 'should call the loader with serverPaging pageSize and pageNumber parameters', ->
            expect(@loader).toHaveBeenCalledWith { pageSize: 10, pageNumber: 1 }

        it 'should set the items observable to the value passed back from the loader', ->
            expect(@dataSource.items()).toEqual [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        it 'should set the pageItems observable to the first page of the return items', ->
            expect(@dataSource.pageItems()).toEqual [1, 2, 3, 4, 5]

        it 'should set the pageNumber observable to 1', ->
            expect(@dataSource.pageNumber()).toEqual 1

        it 'should set the pageCount observable to 4, the client page count.', ->
            expect(@dataSource.pageCount()).toEqual 4

        it 'should set the totalCount observable to the totalCount returned from the server', ->
            expect(@dataSource.totalCount()).toEqual @allServerData.length

        it 'should set the pageSize observable to the clientPaging size', ->
            expect(@dataSource.pageSize()).toEqual 5
            expect(@dataSource.pageSize()).toEqual 5

    describe 'When a data source is loaded, with high client to server page ratio', ->
        beforeEach ->
            @allServerData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
            @loader = @spy (o, callback) => 
                start = (o.pageNumber - 1) * o.pageSize
                end = start + o.pageSize

                callback 
                    items: @allServerData.slice start, end
                    totalCount: @allServerData.length

            @dataSource = new bo.DataSource 
                provider: @loader
                clientPaging: 2
                serverPaging: 10

            @dataSource.load()

        it 'should call the loader with serverPaging pageSize and pageNumber parameters', ->
            expect(@loader).toHaveBeenCalledWith { pageSize: 10, pageNumber: 1 }

        it 'should correctly page items', ->
            expect(@dataSource.pageItems()).toEqual [1, 2]

    describe 'When a pageNumber is changed to page still within server page, after first load, with client and server paging', ->
        beforeEach ->
            # Arrange
            @allServerData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
            @loader = @spy (o, callback) => 
                start = (o.pageNumber - 1) * o.pageSize
                end = start + o.pageSize

                callback 
                    items: @allServerData.slice start, end
                    totalCount: @allServerData.length

            @dataSource = new bo.DataSource 
                provider: @loader
                clientPaging: 5
                serverPaging: 10

            @dataSource.load()
            expect(@loader).toHaveBeenCalledOnce()

            # Act
            @dataSource.pageNumber 2

        it 'should not call the loader again', ->
            expect(@loader).toHaveBeenCalledOnce() # Only on first load

        it 'should set the pageItems observable to the page of items specified by page number', ->
            expect(@dataSource.pageItems()).toEqual [6, 7, 8, 9, 10]

        it 'should not reset the pageNumber that has been set', ->
            expect(@dataSource.pageNumber()).toEqual 2

        it 'should set the pageCount observable to 4', ->
            expect(@dataSource.pageCount()).toEqual 4

        it 'should set the totalCount observable to the value passed back from the loader', ->
            expect(@dataSource.totalCount()).toEqual @allServerData.length

        it 'should set the pageSize observable to the clientPaging size', ->
            expect(@dataSource.pageSize()).toEqual 5

    describe 'When a pageNumber is changed to page not within server page, after first load, with client and server paging', ->
        beforeEach ->
            # Arrange
            @allServerData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
            @loader = @spy (o, callback) => 
                start = (o.pageNumber - 1) * o.pageSize
                end = start + o.pageSize

                callback 
                    items: @allServerData.slice start, end
                    totalCount: @allServerData.length

            @dataSource = new bo.DataSource 
                provider: @loader
                clientPaging: 5
                serverPaging: 10

            @dataSource.load()
            expect(@loader).toHaveBeenCalledOnce()

            # Act
            @dataSource.pageNumber 3

        it 'should call the loader again', ->
            expect(@loader).toHaveBeenCalledTwice()

        it 'should call the loader with serverPaging pageSize and pageNumber parameters', ->
            expect(@loader).toHaveBeenCalledWith { pageSize: 10, pageNumber: 2 }

        it 'should set the pageItems observable to the page of items specified by page number', ->
            expect(@dataSource.pageItems()).toEqual [11, 12, 13, 14, 15]

        it 'should not reset the pageNumber that has been set', ->
            expect(@dataSource.pageNumber()).toEqual 3

        it 'should set the pageCount observable to 4', ->
            expect(@dataSource.pageCount()).toEqual 4

        it 'should set the totalCount observable to the value passed back from the loader', ->
            expect(@dataSource.totalCount()).toEqual @allServerData.length

        it 'should set the pageSize observable to the clientPaging size', ->
            expect(@dataSource.pageSize()).toEqual 5