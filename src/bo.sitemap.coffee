#reference "bo.coffee"
#reference "bo.bus.coffee"

class SitemapNode
    constructor: (sitemap, @name, @definition) ->
        bo.arg.ensureDefined sitemap, "sitemap"
        bo.arg.ensureDefined name, "name"
        bo.arg.ensureDefined definition, "definition"

        @parent = null
        @metadata = @definition.metadata
        @children = ko.observableArray []

        @isCurrent = ko.computed =>
            sitemap.currentNode() is @

        if definition.url
            new bo.routing.Route name, definition.url

            bo.bus.subscribe "routeNavigated:#{name}", (data = {}) =>
                sitemap.currentNode @
                sitemap.regionManager.activate @definition.parts, data.parameters

        @hasRoute = definition.url?

        if definition.isInNavigation?
            if ko.isObservable definition.isInNavigation 
                @isVisible = definition.isInNavigation 
            else 
                @isVisible = ko.observable definition.isInNavigation
        else
            @isVisible = ko.observable true

        @isActive = ko.computed =>
            @isCurrent() or _.any(@children(), (c) -> c.isActive())
            
        @hasChildren = ko.computed =>
            _.any(@children(), (c) -> c.isVisible())

    addChild: (child) ->
        @children.push child
        child.parent = @

    # Gets an array that contains the ancestors or this node, including this node. The order
    # will be from the root down to this node (e.g. result[0] is the root node, result[pathLength] is this
    # node)
    getAncestorsAndThis: ->
        (@parent?.getAncestorsAndThis() || []).concat [@]

class bo.Sitemap
    # Array of property names that have a meaning within a node definition. Used to allow definition
    # of child nodes by having a property with name that is not one of these values.
    @knownPropertyNames =  ['url', 'parts', 'isInNavigation', 'metadata']

    constructor: (@regionManager, pages) ->
        bo.arg.ensureDefined regionManager, "regionManager"
        bo.arg.ensureDefined pages, "pages"

        @currentNode = ko.observable()
        @nodes = []
        @breadcrumb = ko.computed =>
            if @currentNode()?
                @currentNode().getAncestorsAndThis()
            else
                []

        for pageName, pageDefinition of pages
            @nodes.push @_createNode pageName, pageDefinition

    _createNode: (name, definition) ->
        node = new SitemapNode @, name, definition

        for subName, subDefinition of definition when not (_(bo.Sitemap.knownPropertyNames).contains subName)
            node.addChild @_createNode subName, subDefinition

        node