# A binding handler that identifies it should directly apply to any
# elements with a given name with should have a `tag` property that
# is either a `string` or an `object`. 
#
# A string representation takes the form of
# `appliesToTagName[->replacedWithTagName]`, for example 'input'
# or 'tab->div' to indicate a binding handler that applies to
# an input element but requires no transformation and a binding
# handler that should replace any `tab` elements with a `div` element.
#
# An object can be specified instead of a string which consists of the
# following properties:
#
# * `appliesTo`: The name of the tag (*must be uppercase*) the binding
# handler applies to and should be data-bound to in all cases.
#
# * `replacedWith`: An optional property that identifies the name of the
# tag that the element should be replaced with. This is needed to support
# older versions of IE that can not properly support custom, non-standard
# elements out-of-the-box.
tagBindingProvider = ->
    realBindingProvider = new ko.bindingProvider()

    # The definition of what tag to apply a binding handler, and the
    # optional replacement element name can be defined as a string
    # which needs to be parsed.
    processBindingHandlerTagDefinition = (bindingHandler) ->
        if _.isString bindingHandler.tag
            split = bindingHandler.tag.split "->"

            if split.length is 1
                bindingHandler.tag =
                    appliesTo: split[0].toUpperCase()
            else
                bindingHandler.tag =
                    appliesTo: split[0].toUpperCase()
                    replacedWith: split[1]

    mergeAllAttributes = (source, destination) ->
        if document.body.mergeAttributes
            destination.mergeAttributes source, false
        else
            for attr in source.attributes
                destination.setAttribute attr.name, attr.value

    findTagCompatibleBindingHandlerName = (node) ->
        if node.tagHandler?
            node.tagHandler
        else
            tagName = node.tagName

            if tagName?
                _.find _.keys(koBindingHandlers), (key) ->
                    bindingHandler = koBindingHandlers[key]

                    processBindingHandlerTagDefinition bindingHandler

                    bindingHandler.tag? and bindingHandler.tag.appliesTo is tagName

    @preprocessNode = (node) ->
        tagBindingHandlerName = findTagCompatibleBindingHandlerName node
        tagBindingHandler = koBindingHandlers[tagBindingHandlerName]

        # We assume that if this is for a 'tag binding handler' it refers to an unknown
        # node so we use the specified replacement node from the binding handler's
        # tag option.
        if tagBindingHandlerName and tagBindingHandler.tag?.replacedWith?
            nodeReplacement = document.createElement tagBindingHandler.tag.replacedWith
            mergeAllAttributes node, nodeReplacement

            nodeReplacement.tagHandler = tagBindingHandlerName

            ko.utils.replaceDomNodes node, [nodeReplacement]

            return nodeReplacement

    @nodeHasBindings = (node, bindingContext) ->
        tagBindingHandler = findTagCompatibleBindingHandlerName node
        isCompatibleTagHandler = tagBindingHandler isnt undefined

        realBindingProvider.nodeHasBindings(node, bindingContext) or isCompatibleTagHandler

    @getBindings = (node, bindingContext) ->
        # parse the bindings with the real binding provider
        existingBindings = realBindingProvider.getBindings node, bindingContext

        tagBindingHandlerName = findTagCompatibleBindingHandlerName node
        
        if tagBindingHandlerName isnt undefined
            existingBindings or existingBindings = {}

            options = true
            optionsAttribute = node.getAttribute 'data-option'

            if optionsAttribute
                # To use the built-in parsing logic we will create a binding
                # string that would be used if this binding handler was being used
                # in a normal data-bind context. With the parsed options we can then
                # extract the value that would be passed for the valueAccessor.
                optionsAttribute = "#{tagBindingHandlerName}: #{optionsAttribute}"                
                options = realBindingProvider.parseBindingsString optionsAttribute, bindingContext
                options = options[tagBindingHandlerName]

            existingBindings[tagBindingHandlerName] = options

        existingBindings

    @

ko.bindingProvider.instance = new tagBindingProvider()