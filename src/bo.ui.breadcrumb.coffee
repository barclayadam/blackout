# reference "bo.utils.coffee"
# reference "bo.bindingHandlers.coffee"
# reference "bo.coffee"

bo.utils.addTemplate 'breadcrumbItem', '''
        <li>
            {{if isCurrent}}
                <span class="current" data-bind="text: name"></span>
            {{else !hasRoute}}
                <span data-bind="text: name"></span>
            {{else}}
                <a href="#" data-bind="navigateTo: name, text: name"></a>
            {{/if}}
        </li>
        '''

bo.utils.addTemplate 'breadcrumbTemplate', '''
        <ul class="bo-breadcrumb" data-bind="template: { name : 'breadcrumbItem', foreach: breadcrumb }"></ul>
        '''

ko.bindingHandlers.breadcrumb = 
    'init': (element, valueAccessor) ->            
        sitemap = ko.utils.unwrapObservable valueAccessor()

        if sitemap
            ko.renderTemplate "breadcrumbTemplate", sitemap, {}, element, "replaceChildren"