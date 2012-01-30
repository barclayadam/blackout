injectDialogTemplate = (name) ->
    id = "dialog-#{bo.utils.toCssClass(name)}"

    if jQuery("##{id}").length is 0
        jQuery("""
                <div id="#{id}" class="bo-dialog">
                    <div class="bo-dialog-region-manager" data-bind="regionManager: _regionManager">
                       <div class="bo-dialog-content" data-bind="region: 'main'" />
                    </div>
                </div>
                """).appendTo 'body'
    
    jQuery("##{id}")[0]

# Represents a dialog, containing a single `bo.Part` that can be activated
# and shown in an overlay (modal or not) on the screen.
#
# A dialog is represented by a `bo.Part`, which provides the loading of view
# models and template loading in the same manner as would typically be used
# as part of the site (e.g. see `bo.Sitemap`).
class bo.Dialog
    constructor: (@part) ->
        @_regionManager = new bo.RegionManager()

    _construct: ->
        @_dialogElement = injectDialogTemplate @part.name
        ko.applyBindings @, @_dialogElement

        @_construct = ->

    # Shows this dialog, passing the `parameters` (if any) on to the view model's
    # `show` method, in the same manner as parameters passed as part of navigation.
    show: (parameters) ->
        @_construct()
        @_regionManager.activate [@part], parameters

        dialogOptions =
            isModal: true

        if @part.viewModel.getDialogOptions?
            dialogOptions = _.extend dialogOptions, @part.viewModel.getDialogOptions()  

        jQuery(@_dialogElement).dialog dialogOptions

    # Closes this dialog.
    close: () ->
        jQuery(@_dialogElement).dialog 'close'

ko.bindingHandlers.closeDialog =
    init: (element, valueAccessor) ->
        $element = jQuery element
        
        $element.click ->
            jQuery(element).parents('.bo-dialog').dialog 'close'

            false

bo.utils.addTemplate 'confirmationDialog',  '''
    <div class="bo-confirmation">
        <span class="text" data-bind="text: questionText" />
    </div>
'''

class ConfirmationDialog
    # Constructs a new confirmation dialog, using the title and question
    # text provided.
    #
    # If only one parameter is passed then no title will be set, else the first
    # parameter will be used as the dialog's title, and the second as the question
    # text.
    constructor: (title, questionText) ->
        @_deferred = new jQuery.Deferred()

        if questionText?
            @title = title
            @questionText = questionText
        else
            @questionText = title

    promise: ->
        @_deferred.promise()

    getDialogOptions: ->
        _this = @

        {
            title: @title

            width: 500,
            height: 250

            buttons:
                'Yes': ->
                    _this._deferred.resolve()
                    # TODO: This is horrible and too closely linked to jQuery UI dialog.
                    # Need to allow closing of dialog without this knowledge.
                    jQuery(@).dialog "close" 

                'No': ->
                    _this._deferred.reject()
                    jQuery(@).dialog "close" 
        }

bo.Dialog.confirm = (title, questionText) ->
    dialogModel = new ConfirmationDialog title, questionText

    confirmationDialog = new bo.Dialog new bo.Part 'Confirmation', { templateName: 'confirmationDialog', viewModel: dialogModel }
    confirmationDialog.show()

    dialogModel.promise()