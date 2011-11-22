#reference "bo.coffee"

class SitemapNode
    constructor: (sitemap, @name, @definition) ->
        bo.arg.ensureDefined sitemap, "sitemap"
        bo.arg.ensureDefined name, "name"
        bo.arg.ensureDefined definition, "definition"

        @parent = null
        @children = ko.observableArray []

        if definition.url
            bo.routing.routes.add name, definition.url
            sitemap.partManager.register name, part for part in definition.parts if definition.parts

        @hasRoute = definition.url?

        if definition.isInNavigation?
            if ko.isObservable definition.isInNavigation 
                @isVisible = definition.isInNavigation 
            else 
                @isVisible = ko.observable definition.isInNavigation
        else
            @isVisible = ko.observable true

        @isCurrent = ko.computed =>
            currentRoute = bo.routing.router.currentRoute()
            currentRoute?.name is @name

        @isCurrent.subscribe (isCurrent) =>
            sitemap.currentNode @ if isCurrent

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
    @knownPropertyNames =  ['url', 'parts', 'isInNavigation']

    constructor: (@partManager, pages) ->
        bo.arg.ensureDefined partManager, "partManager"
        bo.arg.ensureDefined pages, "pages"

        @currentNode = ko.observable()
        @nodes = []
        @breadcrumb = ko.computed =>
            @currentNode()?.getAncestorsAndThis()

        for pageName, pageDefinition of pages
            @nodes.push @_createNode pageName, pageDefinition

    _createNode: (name, definition) ->
        node = new SitemapNode @, name, definition

        for subName, subDefinition of definition when (jQuery.inArray subName, bo.Sitemap.knownPropertyNames) is -1
            node.addChild @_createNode subName, subDefinition

        node