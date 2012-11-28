toOrderDirection = (order) ->
    if order is undefined or order is 'asc' or order is 'ascending'
        'ascending'
    else 
        'descending'

class bo.Sorter
    constructor: (definition) ->
        @definition = ko.observable ''

        if definition?
            @setSortOrder definition

    setSortOrder: (definition) ->      
        @definition _(definition.split(',')).map (p) ->
            p = ko.utils.stringTrim p

            indexOfSpace = p.indexOf ' '

            if indexOfSpace > -1
                return {
                    name: p.substring 0, indexOfSpace
                    order: toOrderDirection p.substring indexOfSpace + 1
                }
            else
                return {
                    name: p
                    order: 'ascending'
                }

    # Sorts the specified array using the definition that has previously
    # been set for this sorter, or returning the array as-is if not
    # sorting definition has been specified. 
    sort: (array) ->
        if @definition()
            array.sort (a, b) => 
                for p in @definition()
                    if a[p.name] > b[p.name]
                        return if p.order is 'ascending' then 1 else -1
                    
                    if a[p.name] < b[p.name]
                        return if p.order is 'ascending' then -1 else 1

                0
        else
            array

    # Gets the sort order of the specified property, returning `undefined`
    # if the property has no sort order defined. The string values are the
    # long-form description, either `ascending` or `descending`, regardless of
    # how they will originally specified.
    getPropertySortOrder: (propertyName) ->
        if @definition()? and @definition().length > 0
            ordering = _.find @definition(), (o) -> o.name is propertyName            
            ordering?.order    

    # Returns a string representation of this `Sorter`, defined as a
    # comma-delimited list of property names and their sort order (always
    # the full `descending` or `ascending` string value):
    #
    # `propertyName [ascending|descending](, propertyName [ascending|descending])*
    toString: () ->
        _.reduce @definition(), ((memo, o) -> 
                prop = "#{o.name} #{o.order}"

                if memo 
                    "#{memo}, #{prop}" 
                else 
                    prop
            ), ''