# reference "bo.sitemap.coffee"

bo.utils.addTemplate 'breadcrumbTemplate', '''
        <ul class="bo-breadcrumb" data-bind="foreach: breadcrumb">
            <li>
                <!-- ko ifnot: hasRoute -->
                    <span class="current" data-bind="text: name"></span>
                <!-- /ko -->

                <!-- ko if: hasRoute -->
                    <a href="#" data-bind="navigateTo: name, text: name"></a>
                <!-- /ko -->
            </li>
        </ul>
        '''

ko.bindingHandlers.breadcrumb =
    'init': (element, valueAccessor) ->
        sitemap = ko.utils.unwrapObservable valueAccessor()

        if sitemap
            ko.renderTemplate "breadcrumbTemplate", sitemap, {}, element, "replaceNode"

        { "controlsDescendantBindings": true }