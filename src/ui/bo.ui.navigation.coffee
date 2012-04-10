# reference "bo.utils.coffee"
# reference "bo.bindingHandlers.coffee"
# reference "bo.coffee"

bo.utils.addTemplate 'navigationItem', '''
        <li data-bind="css: { active: isActive, current: isCurrent, 'has-children': hasChildren, 'has-route': hasRoute, 'has-focus': hasFocusedChildren }, 
                       attr: { id : bo.utils.toCssClass(name) }">
            <span class="name" data-bind="text: name, 
                                          command: [{ callback: navigateTo, event: 'click', keyboard: 'return' }],
                                          tabIndex: hasFocus"></span>

            <ul class="bo-navigation-sub-item" data-bind="template: { name : 'navigationItem', foreach: visibleChildren }"></ul>
        </li>
        '''

bo.utils.addTemplate 'navigationTemplate', '''
        <ul class="bo-navigation"
            role="navigation" 
            tabindex="0" 
            data-bind="template: { name : 'navigationItem', foreach: sitemap.visibleChildren },
                       sitemapFocus: true,
                       command: [{ callback: focusNext, keyboard: 'right' },
                                 { callback: focusPrevious, keyboard: 'left'},
                                 { callback: focusUp, keyboard: 'up'},
                                 { callback: focusDown, keyboard: 'down'}]"></ul>
        '''

ko.bindingHandlers.sitemapFocus =
    init: (element) ->
        $element = jQuery(element)

        $element.on 'blur focusout', 'ul, li', ->
            $element.removeClass 'has-focus'

        $element.on 'focus focusin', 'ul, li', ->
            $element.addClass 'has-focus'

class SitemapViewModel
    constructor: (@sitemap) ->
        @focusedNode = ko.observable()

        @_augment child for child in sitemap.children()

    _doFocusNext: (node) ->
        if node?
            siblings = node.parent.visibleChildren()
            currentIndex = siblings.indexOf node

            if currentIndex + 1 < siblings.length
                @focusedNode siblings[currentIndex + 1]
            else
                @_doFocusNext node.parent

    focusNext: () ->
        focused = @focusedNode()

        if focused?
            @_doFocusNext focused
        else
            @focusedNode @sitemap.visibleChildren()[0]

    focusPrevious: (node) ->
        node = node or @focusedNode()

        if node? and node.parent?
            siblings = node.parent.visibleChildren()
            currentIndex = siblings.indexOf node

            if currentIndex - 1 >= 0
                @focusedNode siblings[currentIndex - 1]
            else
                @focusPrevious node.parent

    focusUp: () ->
        focused = @focusedNode()

        if focused? and focused.parent?
            @focusedNode focused.parent

    focusDown: () ->
        focused = @focusedNode()

        if focused? and focused.visibleChildren().length > 0
            @focusedNode focused.visibleChildren()[0]

    _augment: (node) ->
        node.hasFocus = ko.computed =>
            @focusedNode() is node

        node.hasFocusedChildren = ko.computed
            read: -> node.hasFocus() or _.any(node.children(), (c) -> c.hasFocusedChildren())      
            deferEvaluation: true

        @_augment child for child in node.children()

ko.bindingHandlers.navigation = 
    init: (element, valueAccessor) ->
        sitemap = ko.utils.unwrapObservable valueAccessor()

        if sitemap
            ko.renderTemplate "navigationTemplate", new SitemapViewModel(sitemap), {}, element, "replaceChildren"

         { "controlsDescendantBindings": true }