# reference "bo.utils.coffee"
# reference "bo.coffee"

window.bo.ui = window.bo.ui || {}

class TreeNode
    constructor: (@data, parent, @viewModel) ->
        @isTreeNode = true

        @parent = ko.observable parent
        @id = @data.id

        @safeId = _.uniqueId('node-')
        @nodeTextId = _.uniqueId('node-label-')

        @name = ko.observable @data.name
        @isRoot = not parent?
                
        @type = @data.type || 'folder'
        @cssClass = if @data.cssClass? then "#{@data.cssClass} #{bo.utils.toCssClass @type}" else bo.utils.toCssClass @type

        @contextMenu = @viewModel.getContextMenu @type

        @inlineMenus = _.filter @contextMenu, (i) ->
            i.separator is undefined

        @checkState = ko.observable @data.isChecked || false
        @checkState.subscribe (newValue) =>
            if newValue is true
                @viewModel.checkedNodes.push @
            else
                @viewModel.checkedNodes.remove @

            @parent()._updateCheckState() if not @isRoot

        parent?.checkState.subscribe (newValue) =>
            @checkState newValue if newValue != "mixed"

        @checkState @parent().checkState() if parent

        @isVisible = bo.utils.asObservable @data.isVisible ? true                
        @isOpen = ko.observable @data.isOpen ? false
        @expanded = ko.computed => @isOpen().toString()

        @isSelected = ko.computed =>
            @viewModel.selectedNode() is @

        @isFocused = ko.computed =>
            @viewModel.focusedNode() is @

        @isRenaming = ko.observable false
        @editingName = ko.observable()

        @isRenaming.subscribe (newValue) =>
            if newValue
                @editingName(@name())
        
        @children = ko.observableArray([]).extend
            onDemand: =>
                if @data.loadChildren
                    @data.loadChildren (loadedChildren) => @setChildren loadedChildren
        
        @isLeaf = ko.computed =>
            @children.loaded() and @children().length is 0 and not @isRoot

        @level = ko.computed =>
            if @isRoot then 1 else @parent().level() + 1

        @indent = ko.computed =>
            "#{(@level() - 1) * 11}px"
                        
        @_setOption o for o in ["isDraggable", "isDropTarget", "canAddChildren", "childType", "renameAfterAdd", "canRename", "canDelete", "defaultChildName", "dragTemplate"]       

        @setChildren (@data.children || []) if not @data.loadChildren
        @children.load() if @isOpen()

    getFullPath: (includeRoot) ->
        isLastNode = @parent() is null || (@parent().isRoot and !includeRoot)
        
        if isLastNode
            @name()
        else
            parentName = (if !isLastNode then @parent().getFullPath(includeRoot) else '')
            "#{parentName}/#{@name()}"

    setChildren: (childrenToConvert) ->
        @children (@_createChild n for n in childrenToConvert)

    select: ->        
        unless @viewModel.selectedNode() is @
            @_executeHandler 'onSelect', =>
                @viewModel.selectedNode @

                @focus()
        
    toggleFolder: ->
        @children.load =>
            @isOpen !@isOpen()

    beginRenaming: ->
        if @canRename
            @select()
            @isRenaming true

    cancelRenaming: ->
        @isRenaming false
        @focus()

    commitRenaming: ->
        if @isRenaming()
            @isRenaming false

            if @editingName() and @name() != @editingName()
                @_executeHandler 'onRename', @name(), @editingName(), =>
                    @name(@editingName())

        @focus()

    canAcceptDrop: (e) ->
        @_executeHandler 'canAcceptDrop', e, (droppable) =>
            (droppable instanceof TreeNode) and @isDropTarget and droppable != @ and @ != droppable.parent() and !@isDescendantOf droppable

    acceptDrop: (droppable) ->
        if droppable instanceof TreeNode
            droppable.moveTo @
        else
            @_executeHandler 'onAcceptUnknownDrop', droppable

    isDescendantOf: (parent) ->
        not @isRoot && (@parent() == parent || @parent().isDescendantOf parent)
        
    moveTo: (newParent) ->
        @_executeHandler "onMove", newParent, =>
            @parent().children.remove @
            @parent newParent

            newParent.children.load =>
                newParent.children.push @
                newParent.isOpen true
                @select()

    deleteSelf: ->
        if @canDelete
            @_executeHandler 'onDelete', =>
                child.deleteSelf() for child in @children()
                
                @parent().children.remove @
                @parent().select()

    open: ->
        @children.load =>
            @isOpen true

    close: ->
        @isOpen false

    previousSibling: ->
        if @isRoot
            null
        else
            nodeIndex = @parent().children.indexOf @

            if nodeIndex is 0
               null
            else
                @parent().children()[nodeIndex - 1]

    nextSibling: ->
        if @isRoot
            null
        else
            nodeIndex = @parent().children.indexOf @

            if nodeIndex is @parent().children().length - 1
               null
            else
                @parent().children()[nodeIndex + 1]
    
    focus: ->
        @viewModel.focusedNode @

    focusPrevious: ->
        if not @isRoot
            previousSibling = @previousSibling()

            if previousSibling
                previousSibling = previousSibling.children()[previousSibling.children().length - 1] while previousSibling.isOpen() and previousSibling.children().length > 0
                
                previousSibling.focus()
            else
                @parent().focus()

    focusNext: ->
        if @isRoot
            @children.load =>
                @children()[0].focus() if @children().length > 0
        else
            if @isOpen() and @children().length > 0
                @children()[0].focus()
            else
                nextSibling = @nextSibling()

                if nextSibling
                    nextSibling.focus()
                else
                    parent = @parent()
                    parent = parent.parent() while not parent.nextSibling() and not parent.isRoot
                    
                    if parent.nextSibling()
                        parent.nextSibling().focus()

    addNewChild: (options) ->
        if @canAddChildren
            options.type = @childType || @type if not options.type
            options.name = @defaultChildName if not options.name

            @_executeHandler 'onAddNewChild', options.type, options.name, (data) =>
                @addChild data, (newNode) =>
                    newNode.isRenaming true if @renameAfterAdd

    addChild: (data, completed) ->
        if data
            newNode = @_createChild data

            @children.load =>
                @open()
                @children.push newNode

                newNode.select()

                completed newNode if completed

    _updateCheckState: ->
        if @children().length > 0
            currentChildState = @children()[0].checkState()

            for c in @children()
                childState = c.checkState()

                if childState != currentChildState
                    currentChildState = "mixed"
                    break

                currentChildState = childState
            
            @checkState currentChildState

        @parent()._updateCheckState() if not @isRoot
        
    _executeHandler: (name, others...) ->
        @viewModel.options.handlers[name].apply(@, [@, others...])                    

    _setOption: (optionName) ->
        @[optionName] = undefined

        for o in [@data[optionName], @viewModel.options.nodeDefaults[@type]?[optionName], @viewModel.options.nodeDefaults[optionName]]
            if o?
                @[optionName] = o
                break

    _createChild: (data) ->
        new TreeNode data, @, @viewModel
        
class TreeViewModel
    constructor: (configuration) ->
        @options = jQuery.extend true, {}, TreeViewModel.defaultOptions, configuration

        @selectedNode = ko.observable null
        @focusedNode = ko.observable null
        @checkedNodes = ko.observableArray()

        @activeDescendant = ko.computed =>
            selectedNode = @selectedNode()

            if selectedNode?
                selectedNode.safeId
            else
                ''

        # Up
        @selectPrevious = ->
            focused = (@focusedNode() || @root)

            focused.focusPrevious()

        # Right
        @open = ->
            focused = (@focusedNode() || @root)

            if focused.isOpen()
                if focused.children().length > 0
                    focused.children()[0].focus()
            else
                focused.open()

        # Left
        @close = ->
            focused = (@focusedNode() || @root)

            if focused.isOpen() and focused.children().length > 0
                focused.close()
            else 
                if not focused.isRoot
                    focused.parent().focus()

        # Down
        @selectNext = ->
            focused = (@focusedNode() || @root)

            focused.focusNext()

        @deleteSelf = ->
            if @focusedNode()
                @focusedNode().deleteSelf()

        @beginRenaming = ->
            if @focusedNode()
                @focusedNode().beginRenaming()

        @selectFocused = ->
            if @focusedNode()
                @focusedNode().select()

        @getContextMenu = (nodeType) =>
            @options.contextMenus[nodeType] if @options.contextMenus
            
        @root = new TreeNode @options.root, null, @

    addChildren: (children) ->
        @root.setChildren children

TreeViewModel.defaultOptions = 
    root:
        name: 'Root'
        isOpen: true
        children: []
        canDelete: false
        isDraggable: false

    checksEnabled: false

    nodeDefaults:
        isDraggable: true
        isDropTarget: true
        canAddChildren: true
        childType: 'folder'
        renameAfterAdd: true
        canRename: false
        canDelete: true
        defaultChildName: 'New Node'

    handlers:
        onSelect: (node, onSuccess) -> onSuccess()
        onAddNewChild: (node, type, name, onSuccess) -> onSuccess()
        onRename: (node, from, to, onSuccess) -> onSuccess()
        onDelete: (node, onSuccess) -> onSuccess()
        onMove: (node, newParent, onSuccess) -> onSuccess()
        canAcceptDrop: (node, droppable, defaultAcceptance) -> defaultAcceptance droppable
        onAcceptUnknownDrop: (node, droppable) ->

bo.utils.addTemplate 'treeNodeTemplate', '''
        <li role="treeitem" data-bind="treeNode: true">        
            <div class="tree-node" 
                 data-bind="draggable: { enabled: isDraggable, template: dragTemplate },
                            dropTarget: { canAccept : canAcceptDrop, onDropComplete: acceptDrop}, 
                            hoverClass: 'ui-state-hover',                      
                            contextMenu: contextMenu,
                            tabIndex: isFocused">
                <span data-bind="click: toggleFolder, clickBubble : false, 
                                 css: { 'handle': true, 'ui-icon': true, 'ui-icon-triangle-1-se': isOpen, 'ui-icon-triangle-1-e': !isOpen() },
                                 style: { marginLeft: indent }">&nbsp;</span>

                <!-- ko if: viewModel.options.checksEnabled -->
                    <input type="checkbox" class="checked" data-bind="indeterminateCheckbox: checkState" />
                <!-- /ko -->
                                
                <!-- ko if: isRenaming -->
                    <input class="rename" type="text" data-bind="
                               value: editingName, 
                               valueUpdate: 'keyup', 
                               hasfocus: isRenaming(), 
                               command: [{ callback: commitRenaming, event: 'blur', keyboard: 'return' },
                                         { callback: cancelRenaming, keyboard: 'esc' }]" />
                <!-- /ko -->

                <!-- ko if: !isRenaming() -->
                    <label data-bind="visible: !isRenaming(), text: name, attr: { id: nodeTextId }" unselectable="on"></label>
                    <ul data-bind="inlineContextMenu: contextMenu" />
                <!-- /ko -->
            </div>
            
            <ul role="group" data-bind='visible: isOpen, template: { renderIf: isOpen, name: "treeNodeTemplate", foreach: children }'></ul>
        </li>
        '''

bo.utils.addTemplate 'treeTemplate', '''
        <ul 
            class="bo-tree" 
            role="tree" 
            tabindex="0"
            data-bind="treeRoot: true,
                       command: [{ callback: selectPrevious, keyboard: 'up' },
                                 { callback: open, keyboard: 'right' },
                                 { callback: close, keyboard: 'left' },
                                 { callback: selectNext, keyboard: 'down' },
                                 { callback: deleteSelf, keyboard: 'del' },
                                 { callback: beginRenaming, keyboard: 'f2' },
                                 { callback: selectFocused, keyboard: 'space' }]"></ul>
        '''

bindAttribute = (element, attribute, observable) ->
    observable.subscribe ->
        element.setAttribute attribute, observable()

    element.setAttribute attribute, observable()

bindCssClass = (element, className, observable) ->
    observable.subscribe ->
        ko.utils.toggleDomNodeCssClass element, className, observable()

    ko.utils.toggleDomNodeCssClass element, className, observable()

ko.bindingHandlers.treeRoot =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        bindAttribute element, 'aria-activedescendant', viewModel.activeDescendant

        ko.renderTemplate 'treeNodeTemplate', viewModel.root, {}, element, "replaceChildren"

        { "controlsDescendantBindings": true}

ko.bindingHandlers.treeNode =
    init: (element, valueAccessor, allBindingsAccessor, viewModel) -> 
        $element = jQuery element

        viewModel.isVisible.subscribe (isVisible) ->
            if isVisible
                $element.show()
            else
                $element.hide()

        element.id = viewModel.safeId
        element.class = viewModel.cssClass
        element.setAttribute 'aria-labelledby', viewModel.nodeTextId

        ko.utils.toggleDomNodeCssClass element, viewModel.cssClass, true
        ko.utils.toggleDomNodeCssClass element, 'tree-item', true

        bindAttribute element, 'aria-level', viewModel.level
        bindAttribute element, 'aria-expanded', viewModel.expanded
        bindAttribute element, 'aria-selected', viewModel.isSelected

        bindCssClass element, 'leaf', viewModel.isLeaf
        bindCssClass element, 'open', viewModel.isOpen
        bindCssClass element, 'rename', viewModel.isRenaming
        bindCssClass element, 'selected', viewModel.isSelected
        bindCssClass element, 'focused', viewModel.isFocused
        bindCssClass element, 'children-loading', viewModel.children.isLoading

        $element.on 'click', ->
            viewModel.select()

            false

ko.bindingHandlers.tree =
    init: (element, valueAccessor) ->
        value = valueAccessor()

        ko.renderTemplate "treeTemplate", value, {}, element, "replaceNode"

bo.ui.Tree = TreeViewModel
