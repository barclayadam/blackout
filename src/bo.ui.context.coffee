# reference "bo.utils.coffee"
# reference "bo.bindingHandlers.coffee"
# reference "bo.coffee"

class MenuItem
    constructor: (@data, @container) ->
        @dataItem = {}
        @text = ko.observable @data.text || ''
        @iconCssClass = ko.observable @data.iconCssClass || ''
        @separator = ko.observable @data.separator is true
        @disabled = ko.observable @data.disabled is false

        @run = if _.isFunction @data.run then @data.run else eval(@data.run)
        
        @subMenu = new Menu { items: @data.items }, @container if @data.items?.length > 0

    hasChildren: ->
        @subMenu?

    setDataItem: (dataItem) ->
        @dataItem = dataItem

        if @hasChildren()
            subMenuItem.setDataItem dataItem for subMenuItem in @subMenu.items()

    execute: ->
        if @disabled() || not @run
            false
        
        @run(@dataItem)

class Menu
    constructor: (@data, @viewModel) ->
        @cssClass = ko.observable @data.cssClass || @viewModel.cssClass
        @name = ko.observable @data.name

        @items = ko.observableArray (new MenuItem i, @ for i in @data.items)
        
class bo.ui.ContextMenu
    constructor: (configuration) ->
        @cssClass = ko.observable configuration.cssClass || 'ui-context'
        @build = if _.isFunction configuration.build then configuration.build else eval(configuration.build)
        @contextMenus = ko.observableArray (new Menu menu, @ for menu in configuration.contextMenus)

bo.utils.addTemplate 'contextItemTemplate', '''
        <li data-bind="click: execute, bubble: false, css: { separator : separator, disabled : disabled }">
            {{if !(separator()) }}
                <a href=#" data-bind="css: { parent : hasChildren() }">
                    <!-- Add Image Here? -->
                    <span data-bind="text: text" />
                </a>
            {{/if}}
            {{if hasChildren()}}
                <div style="position:absolute;">
                    <ul data-bind='template: { name: "contextItemTemplate", foreach: subMenu.items }'></ul>
                </div>
            {{/if}}
        </li>
        '''

bo.utils.addTemplate 'contextMenuTemplate', '''
        <div class="ui-context" 
             style="position:absolute;" 
             data-bind="position: { of: mousePosition }">
            <div class="gutterLine"></div>
            <ul data-bind='template: { name: "contextItemTemplate", foreach: menu.items }'></ul>
        </div>
        '''

ko.bindingHandlers.contextMenu = 
    'init': (element, valueAccessor, allBindingsAccessor, viewModel) ->            
        value = ko.utils.unwrapObservable valueAccessor()

        if !value
            return

        $element = jQuery element
        parentVM = viewModel
        builder = value.build

        showContextMenu = (evt) ->
            config = value.build evt, parentVM

            if not config?
                return

            menu = value.contextMenus().filter((x) ->
                return x.name() == config.name
            )[0]
                    
            if (menu?)
                jQuery('.ui-context').remove()

                config.menu = menu
                config.mousePosition = evt
                menuContainer = $('<div></div>').appendTo 'body'
                                                    
                # assign the data item
                menuItem.setDataItem parentVM for menuItem in config.menu.items()

                ko.renderTemplate "contextMenuTemplate", config, { }, menuContainer, "replaceNode"

                true
            else
                false
                        
        $element.mousedown (evt) ->
            if evt.which == 3
                !(showContextMenu evt)
            
        $element.bind 'contextmenu', (evt) -> 
            !(showContextMenu evt)

        jQuery('.ui-context').live 'contextmenu', ->
            false
                
        jQuery(document).bind 'keydown', 'esc', ->   
            $('.ui-context').remove()

        jQuery('html').click ->
            $('.ui-context').remove()

ko.bindingHandlers.subContext = 
    'init': (element, valueAccessor, allBindingsAccessor, viewModel) ->
        $element = jQuery element
        value = ko.utils.unwrapObservable valueAccessor()
        width = ko.utils.unwrapObservable viewModel.width()

        if value
            cssClass = '.' + viewModel.container.cssClass()
            jQuery(cssClass, $element).hide()
            $element.hover ->
                $parent = $(@)
                jQuery(cssClass, $parent).first().toggle().position { my: 'left top', at: 'right top', of: $parent, collision: 'flip' }
                