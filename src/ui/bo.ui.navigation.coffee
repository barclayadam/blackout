# reference "bo.utils.coffee"
# reference "bo.bindingHandlers.coffee"
# reference "bo.coffee"

bo.utils.addTemplate 'navigationItem', '''
        <li data-bind="css: { active: isActive, current: isCurrent, 'has-children': hasChildren }, visible: isVisible">
            <!-- ko if: hasRoute -->
                <a href="#" data-bind="navigateTo: name, text: name"></a>
                <span class="after-link"></span>
            <!-- /ko -->
            <!-- ko ifnot: hasRoute -->
                <span data-bind="text: name"></span>
            <!-- /ko -->
            <ul class="bo-navigation-sub-item" data-bind="template: { name : 'navigationItem', foreach: children }"></ul>
        </li>
        '''

bo.utils.addTemplate 'navigationTemplate', '''
        <ul class="bo-navigation" data-bind="template: { name : 'navigationItem', foreach: nodes }"></ul>
        '''

ko.bindingHandlers.navigation = 
    init: (element, valueAccessor) ->
        sitemap = ko.utils.unwrapObservable valueAccessor()

        if sitemap
            ko.renderTemplate "navigationTemplate", sitemap, {}, element, "replaceChildren"

         { "controlsDescendantBindings": true }
