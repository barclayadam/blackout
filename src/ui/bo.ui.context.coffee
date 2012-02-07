# reference "bo.utils.coffee"
# reference "bo.bindingHandlers.coffee"
# reference "bo.coffee"

class MenuItem
    constructor: (@data) ->
        @dataItem = {}
        @text = ko.observable @data.text || ''
        @iconCssClass = ko.observable @data.iconCssClass || ''
        @separator = ko.observable @data.separator is true
        @disabled = ko.observable @data.disabled is false

        @run = if _.isFunction @data.run then @data.run else eval(@data.run)
        
        @subMenu = new Menu { items: @data.items } if @data.items?.length > 0

    hasChildren: ->
        @subMenu?

    setDataItem: (dataItem) ->
        @dataItem = dataItem

        if @hasChildren()
            subMenuItem.setDataItem dataItem for subMenuItem in @subMenu.items()

    execute: ->
        if @disabled() || not @run
            false
        
        @run @dataItem

class Menu
    constructor: (@items) ->
        @items = ko.observableArray (new MenuItem i, @ for i in @items)
        
bo.utils.addTemplate 'contextItemTemplate', '''
        <li data-bind="click: execute, bubble: false, css: { separator : separator, disabled : disabled }">
            <!-- ko ifnot: separator -->
                <a href=#" data-bind="css: { parent : hasChildren() }">
                    <!-- Add Image Here? -->
                    <span data-bind="text: text" />
                </a>
            <!-- /ko -->

            <!-- ko if: hasChildren() -->
                <div style="position: absolute">
                    <ul data-bind='template: { name: "contextItemTemplate", foreach: subMenu.items }'></ul>
                </div>
            <!-- /ko -->
        </li>
        '''

bo.utils.addTemplate 'contextMenuTemplate', '''
        <div class="ui-context" style="position: absolute" data-bind="position: { of: mousePosition }">
            <div class="gutterLine"></div>
            <ul data-bind='template: { name: "contextItemTemplate", foreach: menu.items }'></ul>
        </div>
        '''

bo.utils.addTemplate 'inlineContextMenuTemplate', '''
        <ul class="inline-context-menu" data-bind="foreach: $data.items">
            <li data-bind="click: execute, attr: { 'class': bo.utils.toCssClass(text) }">
                <span class="icon-wrapper" data-bind="hoverClass: 'ui-state-hover'">
                    <span class="ui-icon"></span>
                </span>

                <span class="name" data-bind="text: text"></span>
            </li>
        </ul>
        '''

ko.bindingHandlers.contextMenu = 
    'init': (element, valueAccessor, allBindingsAccessor, viewModel) ->            
        menuItems = ko.utils.unwrapObservable valueAccessor()

        if !menuItems
            return

        menu = new Menu menuItems

        $element = jQuery element
        parentVM = viewModel

        showContextMenu = (evt) ->    
            jQuery('.ui-context').remove()

            config =
                menu: menu
                mousePosition: evt

            menuContainer = jQuery('<div></div>').appendTo 'body'
                                                
            # assign the data item
            item.setDataItem parentVM for item in menu.items()

            ko.renderTemplate "contextMenuTemplate", config, {}, menuContainer, "replaceNode"

        $element.mousedown (evt) ->
            if evt.which == 3
                showContextMenu evt
                false
            
        $element.bind 'contextmenu', (evt) -> 
            showContextMenu evt
            false

        jQuery('.ui-context').live 'contextmenu', ->
            false
                
        jQuery(document).bind 'keydown', 'esc', ->   
            jQuery('.ui-context').remove()

        jQuery('html').click ->
            jQuery('.ui-context').remove()

ko.bindingHandlers.inlineContextMenu = 
    'init': (element, valueAccessor, allBindingsAccessor, viewModel) ->            
        menuItems = ko.utils.unwrapObservable valueAccessor()

        if !menuItems
            return

        menu = new Menu _.filter menuItems, (i) ->
            i.separator is undefined

        item.setDataItem viewModel for item in menu.items()

        ko.renderTemplate "inlineContextMenuTemplate", menu, {}, element, "replaceNode"

ko.bindingHandlers.subContext = 
    'init': (element, valueAccessor, allBindingsAccessor, viewModel) ->
        $element = jQuery element
        value = ko.utils.unwrapObservable valueAccessor()
        width = ko.utils.unwrapObservable viewModel.width()

        if value
            cssClass = '.' + viewModel.container.cssClass()
            jQuery(cssClass, $element).hide()
            $element.hover ->
                $parent = jQuery(@)
                jQuery(cssClass, $parent).first().toggle().position { my: 'left top', at: 'right top', of: $parent, collision: 'flip' }
                