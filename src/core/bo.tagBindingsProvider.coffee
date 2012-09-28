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

    findTagCompatibleBindingHandlerNames = (node) ->
        if node.tagHandlers?
            node.tagHandlers
        else
            tagName = node.tagName

            if tagName?
                _.filter _.keys(koBindingHandlers), (key) ->
                    bindingHandler = koBindingHandlers[key]

                    processBindingHandlerTagDefinition bindingHandler

                    bindingHandler.tag?.appliesTo is tagName
            else
                []

    processOptions = (node, tagBindingHandlerName, bindingContext) ->
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

        options

    @preprocessNode = (node) ->
        tagBindingHandlerNames = findTagCompatibleBindingHandlerNames node

        # We assume that if this is for a 'tag binding handler' it refers to an unknown
        # node so we use the specified replacement node from the binding handler's
        # tag option.
        if tagBindingHandlerNames.length > 0
            node.tagHandlers = tagBindingHandlerNames

            replacementRequiredBindingHandlers = _.filter tagBindingHandlerNames, (key) ->
                koBindingHandlers[key].tag?.replacedWith?
            
            if replacementRequiredBindingHandlers.length > 1
                throw new Error "More than one binding handler specifies a replacement node for the node with name '#{node.tagName}'."

            if replacementRequiredBindingHandlers.length == 1
                tagBindingHandler = koBindingHandlers[replacementRequiredBindingHandlers[0]]

                nodeReplacement = document.createElement tagBindingHandler.tag.replacedWith
                mergeAllAttributes node, nodeReplacement

                ko.utils.replaceDomNodes node, [nodeReplacement]

                nodeReplacement.tagHandlers = tagBindingHandlerNames
                nodeReplacement.originalTagName = node.tagName

                return nodeReplacement

    @nodeHasBindings = (node, bindingContext) ->
        tagBindingHandlers = findTagCompatibleBindingHandlerNames node
        isCompatibleTagHandler = tagBindingHandlers.length > 0

        isCompatibleTagHandler or realBindingProvider.nodeHasBindings(node, bindingContext)

    @getBindings = (node, bindingContext) ->
        # parse the bindings with the real binding provider
        existingBindings = (realBindingProvider.getBindings node, bindingContext) || {}

        tagBindingHandlerNames = findTagCompatibleBindingHandlerNames node
        
        if tagBindingHandlerNames.length > 0
            for tagBindingHandlerName in tagBindingHandlerNames 
                existingBindings[tagBindingHandlerName] = processOptions node, tagBindingHandlerName, bindingContext

        existingBindings

    @

ko.bindingProvider.instance = new tagBindingProvider()