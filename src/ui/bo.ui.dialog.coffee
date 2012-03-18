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
    init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
        value = valueAccessor()
        $element = jQuery element
        
        $element.click ->
            if _.isFunction value
                promise = value.apply viewModel, [viewModel]
                if promise?.done?
                    promise.done ->
                        $element.parents('.bo-dialog').dialog 'close'
                else
                    $element.parents('.bo-dialog').dialog 'close'
            else
                $element.parents('.bo-dialog').dialog 'close'

            false

bo.utils.addTemplate 'confirmationDialog',  '''
    <div class="bo-confirmation">
        <span class="text" data-bind="text: questionText" />

        <div class="button-bar">
            <button class="confirm" class="primary"  data-bind="button: _confirm, closeDialog: true">Yes</button>
            <button class="cancel" class="secondary" data-bind="button: _cancel,  closeDialog: true">No</button>
        </div>
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

    # Gets the `promise` that events can be attached to that will be resolved / rejected
    # when the user clicks the `Yes` or `No` buttons.
    promise: ->
        @_deferred.promise()

    getDialogOptions: ->
        title: @title

        width: 400,
        height: 200,

        modal: true

    _confirm: ->
        @_deferred.resolve()

    _cancel: ->
        @_deferred.reject()

bo.Dialog.confirm = (title, questionText) ->
    dialogModel = new ConfirmationDialog title, questionText

    confirmationDialog = new bo.Dialog new bo.Part 'Confirmation', { templateName: 'confirmationDialog', viewModel: dialogModel }
    confirmationDialog.show()

    dialogModel.promise()

bo.utils.addTemplate 'warningDialog',  '''
    <div class="bo-warning">
        <span class="text" data-bind="text: warningText" />

        <div class="button-bar">
            <button class="ok" class="primary" data-bind="closeDialog: true">Ok</button>
        </div>
    </div>
'''

class WarningDialog
    # Constructs a new warning dialog, using the title and warning
    # text provided.
    #
    # If only one parameter is passed then no title will be set, else the first
    # parameter will be used as the dialog's title, and the second as the warning
    # text.
    constructor: (title, warningText) ->
        @_deferred = new jQuery.Deferred()

        if warningText?
            @title = title
            @warningText = warningText
        else
            @warningText = title

    # Gets the `promise` that events can be attached to that will be resolved / rejected
    # when the user clicks the `Yes` or `No` buttons.
    promise: ->
        @_deferred.promise()

    getDialogOptions: ->
        title: @title

        width: 500,
        height: 250

        modal: true

bo.Dialog.warning = (title, warningText) ->
    dialogModel = new WarningDialog title, warningText

    confirmationDialog = new bo.Dialog new bo.Part 'Warning', { templateName: 'warningDialog', viewModel: dialogModel }
    confirmationDialog.show()

    dialogModel.promise()