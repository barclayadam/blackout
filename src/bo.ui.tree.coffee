# reference "bo.utils.coffee"
# reference "bo.coffee"

window.bo.ui = window.bo.ui || {}

class TreeNode
    constructor: (@data, parent, @viewModel) ->
        @isTreeNode = true

        @parent = ko.observable parent
        @id = @data.id
        @name = ko.observable @data.name
        @isRoot = not parent?
        @contextMenu = @viewModel.contextMenu
        
        @type = @data.type || 'folder'
        @cssClass = @data.cssClass || @type.toLowerCase()        

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
                
        @isOpen = ko.observable @data.isOpen ? false
        @isSelected = ko.observable false
        @isFocused = ko.observable false
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
            if @isRoot then 0 else @parent().level() + 1

        @indent = ko.computed =>
            (@level() * 11) + 'px'
                        
        @_setOption o for o in ["isDraggable", "isDropTarget", "canAddChildren", "childType", "renameAfterAdd", "canRename", "canDelete", "defaultChildName"]		

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
        @viewModel.selectedNode().isSelected false if @viewModel.selectedNode()?
        
        @isSelected true
        @viewModel.selectedNode @

        @focus()
        
    toggleFolder: ->
        @children.load =>
            @isOpen !@isOpen()

    beginRenaming: ->
        if @canRename
            @isRenaming true

    cancelRenaming: ->
        @isRenaming false
        @focus()

    commitRenaming: ->
        if @isRenaming()
            @isRenaming false

            if @name() != @editingName()
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
        @isFocused true

    selectPrevious: ->
        if not @isRoot
            previousSibling = @previousSibling()

            if previousSibling
                previousSibling = previousSibling.children()[previousSibling.children().length - 1] while previousSibling.isOpen() and previousSibling.children().length > 0
                
                previousSibling.select()
            else
                @parent().select()

    selectNext: ->
        if @isRoot
            @children.load =>
                @children()[0].select() if @children().length > 0
        else
            if @isOpen() and @children().length > 0
                @children()[0].select()
            else
                nextSibling = @nextSibling()

                if nextSibling
                    nextSibling.select()
                else
                    parent = @parent()
                    parent = parent.parent() while not parent.nextSibling() and not parent.isRoot
                    
                    if parent.nextSibling()
                        parent.nextSibling().select()

    addNewChild: (options) ->
        if @canAddChildren
            options.type = @childType || @type if not options.type
            options.name = @defaultChildName if not options.name

            @_executeHandler 'onAddNewChild', options.type, options.name, (data) =>
                @addChild data, =>
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
        @checkedNodes = ko.observableArray()

        if @options.contextMenus
            @contextMenu = new bo.ui.ContextMenu {
                contextMenus: @options.contextMenus
                build: (event, dataItem) ->
                    dataItem.select()

                    { name: dataItem.type }
            }
            
        @root = new TreeNode(@options.root, null, @)

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
        onSelect: (onSuccess) -> onSuccess()
        onAddNewChild: (type, name, onSuccess) -> onSuccess()
        onRename: (from, to, onSuccess) -> onSuccess()
        onDelete: (action, onSuccess) -> onSuccess()
        onMove: (newParent, onSuccess) -> onSuccess()
        canAcceptDrop: (node, droppable, defaultAcceptance) -> defaultAcceptance droppable
        onAcceptUnknownDrop: (node, droppable) ->
           
bo.utils.addTemplate 'treeNodeTemplate', '''
        <li data-bind="command: [{ callback: selectPrevious, keyboard: 'up' },
                                 { callback: open, keyboard: 'right' },
                                 { callback: close, keyboard: 'left' },
                                 { callback: selectNext, keyboard: 'down' },
                                 { callback: deleteSelf, keyboard: 'del' },
                                 { callback: beginRenaming, keyboard: 'f2' }],
                        attr: { 'class': cssClass }, 
                        css: { 'tree-item': true, leaf: isLeaf, open: isOpen, rename: isRenaming }">        
            <div class="tree-node" 
                 data-bind="draggable: isDraggable,
                            dropTarget: { canAccept : canAcceptDrop, onDropComplete: acceptDrop}, 
                            contextMenu: contextMenu, 
                            hoverClass: 'ui-state-hover',
                            css: { 'ui-state-active': isSelected, 'ui-state-focus': isFocused, childrenLoading: children.isLoading }, 
                            event: { mousedown: select }">
                <span data-bind="click: toggleFolder, 
                                 css: { 'handle': true, 'ui-icon': true, 'ui-icon-triangle-1-se': isOpen, 'ui-icon-triangle-1-e': !isOpen() },
                                 bubble : false, 
                                 style: { marginLeft: indent }">&nbsp;</span>

                <!-- ko if: viewModel.options.checksEnabled -->
                    <input type="checkbox" class="checked" data-bind="hasfocus: isFocused, indeterminateCheckbox: checkState, visible: viewModel.options.checksEnabled" />
                    <span class="icon"></span>
                    <a href="javascript:void(0)" data-bind="visible: !isRenaming(), text: name" unselectable="on"></a>
                <!-- /ko -->
                <!-- ko ifnot: viewModel.options.checksEnabled -->
                    <span class="icon"></span>
                    <a href="javascript:void(0)" data-bind="hasfocus: isFocused, visible: !isRenaming(), text: name" unselectable="on"></a>
                <!-- /ko -->

                <input class="rename" type="text" data-bind="
                           visible: isRenaming, 
                           value: editingName, 
                           valueUpdate: 'keyup', 
                           hasfocus: isRenaming(), 
                           command: [{ callback: commitRenaming, event: 'blur', keyboard: 'return' },
                                     { callback: cancelRenaming, keyboard: 'esc' }]" />
            </div>
            
            <ul data-bind='visible: isOpen, template: { renderIf: isOpen, name: "treeNodeTemplate", foreach: children }'></ul>
        </li>
        '''

bo.utils.addTemplate 'treeTemplate', '''
        <ul class="bo-tree" data-bind="template: { name : 'treeNodeTemplate', data: root }"></ul>
        '''

ko.bindingHandlers.boTree =
    init: (element, viewModelAccessor) ->
        value = viewModelAccessor()

        ko.renderTemplate "treeTemplate", value, {}, element, "replaceNode"

bo.ui.Tree = TreeViewModel
