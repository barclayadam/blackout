 # Outputs the record count of a datasource.

 ko.bindingHandlers.recordCount = 
     update: (element, valueAccessor, allBindingsAccessor) ->
        dataSource = valueAccessor()

        throw new Error 'A recordCount binding handler must be passed a DataSource as its only parameter.' if not (dataSource instanceof bo.DataSource)

        ko.utils.setTextContent element, dataSource.totalCount()
