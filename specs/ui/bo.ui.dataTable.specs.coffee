class DataItem
    constructor: (@id, @name, @status) ->

dataItemInnerTemplate = '''
    <thead>
        <th data-bind="header: 'id', notSortable: true">Id</th>
        <th data-bind="header: 'name'">Name</th>
        <th data-bind="header: 'userType'">User Type</th>
    </thead>

    <tbody data-bind="tableBody: true">
        <tr data-bind="tableRow: true">
            <td data-bind="column: 'id'" />
            <td data-bind="column: 'name'" />
            <td data-bind="column: 'userType'" />
        </tr>
    </tbody>  
'''

describe 'Data Table', ->
    describe 'with a configured DataTable instance', ->
        beforeEach ->
            @dataSource = new bo.DataSource
                clientPaging: 2

                provider: [{value : 1}, {value : 2}, {value : 3}, {value : 4}]

            @dataTable = new bo.DataTable @dataSource

        it 'should have a dataSource property set to the data source passed in the constructor', ->
            expect(@dataTable.dataSource).toBe @dataSource

        it 'should have an undefined selected item observable', ->
            expect(@dataTable.selectedItem()).toBeUndefined()

        it 'should have an undefined focused item observable', ->
            expect(@dataTable.focusedItem()).toBeUndefined()

        describe 'when options contains a selected observable value', ->
            beforeEach ->
                @externalSelected = ko.observable()
                @dataTable = new bo.DataTable @dataSource,
                    selected: @externalSelected

            it 'should set the observable in the options when an item selected', ->
                @dataTable.select @dataSource.pageItems()[0]

                expect(@externalSelected()).toBe @dataSource.pageItems()[0]

            it 'should set the selectedItem when the observable in the options changes', ->
                @externalSelected @dataSource.pageItems()[0]

                expect(@dataTable.selectedItem()).toBe @dataSource.pageItems()[0]

        describe 'when selecting an item', ->
            beforeEach ->
                @dataTable.select @dataSource.pageItems()[0]

            it 'should set the selectedItem observable', ->
                expect(@dataTable.selectedItem()).toBe @dataSource.pageItems()[0]

            it 'should set the focusedItem observable to be the selected item', ->
                expect(@dataTable.focusedItem()).toBe @dataSource.pageItems()[0]

        describe 'with the first item focused, none selected', ->
            beforeEach ->
                @dataTable.focus @dataSource.pageItems()[0]

            it 'should set the focusedItem observable', ->
                expect(@dataTable.focusedItem()).toBe @dataSource.pageItems()[0]

            it 'should have an undefined selected item observable', ->
                expect(@dataTable.selectedItem()).toBeUndefined()

            it 'should allow focusing the next item', ->
                @dataTable.focusNext()
                expect(@dataTable.focusedItem()).toBe @dataSource.pageItems()[1]

            it 'should not allow focusing the previous item', ->
                @dataTable.focusPrevious()
                expect(@dataTable.focusedItem()).toBe @dataSource.pageItems()[0]

            it 'should allow selecting the focused item', ->
                @dataTable.selectFocused()
                expect(@dataTable.selectedItem()).toBe @dataSource.pageItems()[0]

            describe 'when data source changes page when focused item is selected', ->
                beforeEach ->
                    @dataTable.selectFocused()
                    @dataSource.pageNumber(2)

                it 'should set the selected item to undefined', ->
                    expect(@dataTable.selectedItem()).toBeUndefined()

                it 'should set the focused item to the first item of the page', ->
                    expect(@dataTable.focusedItem()).toBe @dataSource.pageItems()[0]

        describe 'with the last item focused, none selected', ->
            beforeEach ->
                @dataTable.focus @dataSource.pageItems()[1]

            it 'should set the focusedItem observable', ->
                expect(@dataTable.focusedItem()).toBe @dataSource.pageItems()[1]

            it 'should have an undefined selected item observable', ->
                expect(@dataTable.selectedItem()).toBeUndefined()

            it 'should not allow focusing the next item', ->
                @dataTable.focusNext()
                expect(@dataTable.focusedItem()).toBe @dataSource.pageItems()[1]

            it 'should allow focusing the previous item', ->
                @dataTable.focusPrevious()
                expect(@dataTable.focusedItem()).toBe @dataSource.pageItems()[0]

            it 'should allow selecting the focused item', ->
                @dataTable.selectFocused()
                expect(@dataTable.selectedItem()).toBe @dataSource.pageItems()[1]

    describe 'binding handler', ->
        describe 'with a dataSource being passed in directly', ->
            beforeEach ->
                @dataSource = new bo.DataSource
                    provider: [{ 
                            "userType": "Administrator"
                            "name":"Adam Barclay"
                            "id":"93d3726e-182f-43f7-b50d-dcc5e86e6fe5"
                        },
                        { 
                            "userType": "Editor"
                            "name":"John Smith"
                            "id":"1553726e-180f-3e27-b50d-dc8646e6ac14"
                        }]  

                @setHtmlFixture """
                    <table data-bind="dataTable: dataSource">
                        #{dataItemInnerTemplate}
                    </table>
                """

                @applyBindingsToHtmlFixture { dataSource: @dataSource }  
                @grid = @fixture.find("table")                    

            it 'should render a table row for every item in the page being shown', ->
                expect(@grid.find("tbody tr").length).toBe 2

            it 'should render the text of the items using the column binding handler', ->
                expect(@grid.find("tbody tr:first td:eq(0)")).toHaveText "93d3726e-182f-43f7-b50d-dcc5e86e6fe5"
                expect(@grid.find("tbody tr:first td:eq(1)")).toHaveText "Adam Barclay"
                expect(@grid.find("tbody tr:first td:eq(2)")).toHaveText "Administrator" 

            describe 'and a selected binding handler defined on the table, with a selected row', ->
                beforeEach ->
                    @selected = ko.observable()

                    @setHtmlFixture """
                        <table data-bind="dataTable: dataSource, selected: selected">
                            #{dataItemInnerTemplate}
                        </table>
                    """

                    @applyBindingsToHtmlFixture { dataSource: @dataSource, selected: @selected }  
                    @grid = @fixture.find("table")   
                    
                    # Simulate a click to ensure going completely through binding handlers
                    @grid.find("tbody tr:first").click()     
                    
                it 'should set the external selected observable to the selected item', ->
                    expect(@selected()).toBe @dataSource.pageItems()[0]

        describe 'with an empty data source', ->
            beforeEach ->
                @dataSource = new bo.DataSource
                    provider: []  

                @dataTable = new bo.DataTable @dataSource

            describe 'with an empty data source and no empty data template', ->
                beforeEach ->
                    @setHtmlFixture """
                        <table data-bind="dataTable: dataTable">
                            #{dataItemInnerTemplate}
                        </table>
                    """

                    @applyBindingsToHtmlFixture { dataTable: @dataTable }
                    @grid = @fixture.find("table")  
                    
                it 'should not render any contents of the element', ->
                    expect(@grid).toBeEmpty()  

            describe 'with an empty data source and an onNoRecords handler defined', ->
                beforeEach ->
                    @setHtmlFixture """
                        <table data-bind="dataTable: dataTable, onNoRecords: 'emptyElementPlaceholder'">
                            #{dataItemInnerTemplate}
                        </table>

                        <div id="emptyElementPlaceholder">
                            No records found
                        </div>
                    """

                    @applyBindingsToHtmlFixture { dataTable: @dataTable }
                    @grid = @fixture.find("table")  
                    
                it 'should not render any contents of the element', ->
                    expect(@grid).toBeEmpty()  
                    
                it 'should make the element identified by onNoRecords option visible ', ->
                    expect(@fixture.find("#emptyElementPlaceholder")).toBeVisible()
        
        describe 'with a loaded data source', ->
            beforeEach ->
                @dataSource = new bo.DataSource
                    provider: [{ 
                            "userType": "Administrator"
                            "name":"Adam Barclay"
                            "id":"93d3726e-182f-43f7-b50d-dcc5e86e6fe5"
                        },
                        { 
                            "userType": "Editor"
                            "name":"John Smith"
                            "id":"1553726e-180f-3e27-b50d-dc8646e6ac14"
                        }]  

                @dataTable = new bo.DataTable @dataSource

                @setHtmlFixture """
                    <table data-bind="dataTable: dataTable">
                        #{dataItemInnerTemplate}
                    </table>
                """

                @applyBindingsToHtmlFixture { dataTable: @dataTable }

                @grid = @fixture.find("table")  

            it 'should apply a data-table class to the element', ->
                expect(@grid).toHaveClass 'data-table'

            it 'should not mark a column sortable if nonSortable bindingHandler also specified', ->
                expect(@grid.find("th:eq(0)")).toNotHaveClass 'sortable'

            it 'should make each column header sortable', ->
                expect(@grid.find("th:eq(1)")).toHaveClass 'sortable'
                expect(@grid.find("th:eq(2)")).toHaveClass 'sortable'

            it 'should add a class to headers based on column name', ->
                expect(@grid.find("th:eq(0)")).toHaveClass 'id'
                expect(@grid.find("th:eq(1)")).toHaveClass 'name'
                expect(@grid.find("th:eq(2)")).toHaveClass 'user-type'

            it 'should add a class to columns based on column name', ->
                expect(@grid.find("tr td:eq(0)")).toHaveClass 'id'
                expect(@grid.find("tr td:eq(1)")).toHaveClass 'name'
                expect(@grid.find("tr td:eq(2)")).toHaveClass 'user-type'

            it 'should render a table row for every item in the page being shown', ->
                expect(@grid.find("tbody tr").length).toBe 2

            it 'should render the text of the items using the column binding handler', ->
                expect(@grid.find("tbody tr:first td:eq(0)")).toHaveText "93d3726e-182f-43f7-b50d-dcc5e86e6fe5"
                expect(@grid.find("tbody tr:first td:eq(1)")).toHaveText "Adam Barclay"
                expect(@grid.find("tbody tr:first td:eq(2)")).toHaveText "Administrator"

            describe 'and onNoRecords element defined', ->
                beforeEach ->  
                    @dataTable = new bo.DataTable @dataSource

                    @setHtmlFixture """
                        <table data-bind="dataTable: dataTable, onNoRecords: 'emptyElementPlaceholder'">
                            #{dataItemInnerTemplate}
                        </table>

                        <div id="emptyElementPlaceholder">
                            No records found
                        </div>
                    """

                    @applyBindingsToHtmlFixture { dataTable: @dataTable }

                    @grid = @fixture.find("table")  

                it 'should make the element identified by onNoRecords option hidden ', ->
                    expect(@fixture.find("#emptyElementPlaceholder")).toBeHidden()      

            describe 'and selectable = false', ->
                beforeEach ->  
                    @dataTable = new bo.DataTable @dataSource,
                        selectable: false

                    @setHtmlFixture """
                        <table data-bind="dataTable: dataTable">
                            #{dataItemInnerTemplate}
                        </table>
                    """

                    @applyBindingsToHtmlFixture { dataTable: @dataTable }

                    @grid = @fixture.find("table")

                it 'should not set the tabindex attribute', ->
                    expect(@grid[0].tabIndex).toBe -1

                it 'should not include a row with the selected class', ->
                    expect(@grid.find("tbody tr.selected").length).toBe 0

                describe 'when clicking on a row', ->
                    beforeEach ->
                        @grid.find("tbody tr:first").click()

                    it 'should not set the selectedItem of the data table to the clicked on row', ->
                        expect(@dataTable.selectedItem()).toBeUndefined()

                describe 'with a selected item', ->
                    beforeEach ->
                        @dataTable.selectedItem @dataSource.pageItems()[0]

                    it 'should not mark the selected row with the selected class', ->
                        expect(@grid.find("tbody tr:first")).toNotHaveClass 'selected'
                        expect(@grid.find("tbody tr.selected").length).toBe 0

            describe 'and selectable = true', ->
                beforeEach ->  
                    @dataTable = new bo.DataTable @dataSource,
                        selectable: true

                    @setHtmlFixture """
                        <table data-bind="dataTable: dataTable">
                            #{dataItemInnerTemplate}
                        </table>
                    """

                    @applyBindingsToHtmlFixture { dataTable: @dataTable }

                    @grid = @fixture.find("table")

                it 'should set the tabindex attribute of the table to 0', ->
                    expect(@grid[0].tabIndex).toBe 

                it 'should add a selectable class to the table', ->
                    expect(@grid).toHaveClass 'selectable'

                it 'should not include a row with the selected class when no item selected', ->
                    expect(@grid.find("tbody tr.selected").length).toBe 0

                it 'should set the tabindex of the all rows to be -1', ->
                    expect(@grid.find("tbody tr")[0].tabIndex).toBe -1
                    expect(@grid.find("tbody tr")[1].tabIndex).toBe -1

                describe 'when clicking on a row', ->
                    beforeEach ->
                        @grid.find("tbody tr:first").click()

                    it 'should set the selectedItem of the data table to the clicked on row', ->
                        expect(@dataTable.selectedItem()).toBe @dataSource.pageItems()[0]

                describe 'with a selected item', ->
                    beforeEach ->
                        @dataTable.selectedItem @dataSource.pageItems()[0]

                    it 'should mark the selected row with the selected class', ->
                        expect(@grid.find("tbody tr:first")).toHaveClass 'selected'
                        expect(@grid.find("tbody tr.selected").length).toBe 1

                    it 'should set the tabindex of the selected row to 0', ->
                        expect(@grid.find("tbody tr.selected")[0].tabIndex).toBe 0

        describe 'with a remotely loaded data source', ->
            beforeEach ->
                @isLoadingClassDuringLoad = false

                @dataSource = new bo.DataSource
                    provider: @spy (o, callback, dataSource) => 
                        @isLoadingClassDuringLoad = @grid.hasClass 'is-loading'
                        callback []      

                @dataTable = new bo.DataTable @dataSource

                @setHtmlFixture """
                    <table data-bind="dataTable: dataTable, onNoRecords: 'emptyElementPlaceholder'">
                        #{dataItemInnerTemplate}
                    </table>"""
                @grid = @fixture.find("table")

                @applyBindingsToHtmlFixture { dataTable: @dataTable }

                @dataSource.load()

            it 'should add is-loading class to table when data is being loaded', ->
                expect(@isLoadingClassDuringLoad).toBe true
            
            it 'should remove is-loading class to table when data has finished loading', ->
                expect(@grid).toNotHaveClass 'is-loading'