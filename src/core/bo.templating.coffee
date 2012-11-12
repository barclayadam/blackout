templating = bo.templating = {}

# A `template source` that will use the `bo.templating.templates` object
# as storage of a named template.
class StringTemplateSource
    constructor: (@templateName) ->

    text: (value) ->
        ko.utils.unwrapObservable templating.templates[@templateName]

class ExternalTemplateSource
    constructor: (@templateName) ->
        @stringTemplateSource = new StringTemplateSource @templateName

    text: (value) ->
        if templating.templates[@templateName] is undefined
            template = ko.observable templating.loadingTemplate
            templating.set @templateName, template

            loadingPromise = templating.loadExternalTemplate @templateName

            loadingPromise.done template

        @stringTemplateSource.text.apply @stringTemplateSource, arguments

# Creates the custom `blackout` templating engine by augmenting the given templating
# engine with a new `makeTemplateSource` function that first sees if
# a template has been added via. `bo.templating.add` and returns a
# `StringTemplateSource` if found, attempts to create an external
# template source (see `bo.templating.isExternal`) or falls back 
# to the original method if not.
createCustomEngine = (templateEngine) ->
    originalMakeTemplateSource = templateEngine.makeTemplateSource

    templateEngine.makeTemplateSource = (template) ->
        if templating.templates[template]?
            new StringTemplateSource template
        else if templating.isExternal template
            new ExternalTemplateSource template
        else
            originalMakeTemplateSource template

    templateEngine

ko.setTemplateEngine createCustomEngine new ko.nativeTemplateEngine()

# The public API of the custom templating support built on-top of the
# native `knockout` templating engine, providing support for string and
# external templates.
#
# String templates are used most often throughout this library to add
# templates used by the various UI elements, although could be used by
# clients of this library to add small templates through script (for
# most needs external templates or those already defined via a standard
# method available from `knockout` is the recommended approach).
#
# External templates are templates that are loaded from an external source,
# and would typically be served up by the same server that delivered the initial 
# application.

# The template that is to be used when loading an external template,
# set immediately whenever an external template that has not yet been
# loaded is used and bound to, automatically being replaced once the
# template has been successfully loaded.
templating.loadingTemplate = '<div class="template-loading">Loading...</div>'

# Determines whether the specified template definition is 'external',
# whether given the specified name a template could be loaded by passing
# it to the `bo.templating.loadExternalTemplate` method.
#
# By default a template is deemed to be external if it being with the
# preifx `e:` (e.g. `e:My External Template`). When a template is
# identified as external it will be passed to the `bo.templating.loadExternalTemplate`
# method to load the template from the server.
templating.isExternal = (name) ->
    name.indexOf && name.indexOf 'e:' is 0

# The location from which to load external templates, with a `{name}`
# token indicating the location into which to inject the name of the
# template being added.
#
# For example, given an `externalPath` of `/Templates/{name}` and a template
# name of `e:Contact Us` the template will be loaded from `/Templates/Contact Us`.
#
# This property is used from the default implementation of
# `bo.templating.loadExternalTemplate`, which can be completely overriden
# if this simple case does not suffice for a given project.
templating.externalPath = '/Templates/Get/{name}'

templating.loadExternalTemplate = (name) ->
    # The default support is for template names beginning 'e:', strip
    # that identifier out.
    name = name.substring 2

    path = templating.externalPath.replace '{name}', name

    bo.ajax.url(path).get()

# Resets the templating support by removing all data and templates
# that have been previously added.
templating.reset = ->
    templating.templates = { _data: {} }

# Sets a named template, which may be an observable value, making that
# named template available throughout the application using the standard
# knockout 'template' binding handler.
#
# If the value is an observable, when using that template it will be
# automatically re-rendered when the value of the observable changes.
#
# * `name`: The name of the template to add.
# * `template`: The string value (may be an `observable`) to set as the
#   contents of the template.
templating.set = (name, template) ->
    if ko.isWriteableObservable templating.templates[name]
        templating.templates[name] template
    else
        templating.templates[name] = template

templating.reset()