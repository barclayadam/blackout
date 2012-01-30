#reference "../lib/jquery.js"
#reference "../lib/knockout.js"
#reference "bo.coffee"
#reference "bo.routing.coffee"
#reference "bo.bus.coffee"

# Defines a part within the application, containing all the required metadata
# about a part, such as the name of the template to use, in addition to a small
# numbers of methods used to support the activation / deactivation of
# parts.
#
# It is this class that will be subclassed to construct each individual part,
# setting the necessary options in the constructor and overriding any other
# method as necessary to support the required functionality of the 
# part.
class bo.Part extends bo.Bus
    @region: "main"

    constructor: (@name, @options = {}) ->
        bo.arg.ensureDefined name, 'name'

        @title = @options.title || name
        @region = @options.region || Part.region
        @templateName = @options.templateName || bo.utils.toCssClass "part-#{@name}"
        @templatePath = @options.templatePath || "/Templates/Get/#{@name}" if @options.templateName is undefined
        @_isTemplateLoaded = false

        if _.isFunction @options.viewModel
            @viewModelTemplate = @options.viewModel || {}
        else
            @viewModel = @options.viewModel || {}

    canDeactivate: ->	    
        if @viewModel && @viewModel.isDirty? then !(ko.utils.unwrapObservable @viewModel.isDirty) else true
                    
    deactivate: ->

    # Activates this part.
    # The default behaviour on activation is to:
    # 1) Load the template (view) of this part (see @templateName) from the server.
    # 2) Calls the @show method to allow the loading of data (e.g. queries to
    #    fill the part with specific view model concerns).
    # 3) On completion of the show function, remove any current DOM elements from
    #    this parts region, add the template HTML as innerHTML.
    # 4) Apply bindings using this (the current Part) to the content area.
    activate: (parameters) ->
        bo.arg.ensureDefined parameters, 'parameters'

        @publish "partActivating:#{@name}"

        @_activateViewModel()
        
        loadPromises = [@_loadTemplate()]
        showPromises = @_show parameters || []
        showPromises = [showPromises] if not _.isArray showPromises

        allPromises = _.compact loadPromises.concat showPromises

        jQuery.when.apply(@, showPromises).done =>
            @viewModel.reset() if @viewModel.reset

        jQuery.when.apply(@, allPromises).done =>
            @publish "partActivated:#{@name}"

        allPromises

    # A function that will be executed on activation of this part, used to
    # set-up this part with the specified parameters (as taken from the URL).
    _show: (parameters) ->
        bo.arg.ensureDefined parameters, 'parameters'

        if @viewModel.show
            @viewModel.show parameters

    _loadTemplate: ->
        if not @_isTemplateLoaded and @templatePath?
            return jQuery.ajax
                    url: @templatePath
                    dataType: 'html'
                    type: 'GET'
                    success: (template) =>
                        @_isTemplateLoaded = true
                        bo.utils.addTemplate @templateName, template

        bo.utils.resolvedPromise()

    _activateViewModel: ->
        if @viewModelTemplate
            @viewModel = new @viewModelTemplate() || {}
        else
            # Should only call this once if 'static' view model.
            @_activateViewModel = ->
        
        @viewModel.initialise() if @viewModel.initialise