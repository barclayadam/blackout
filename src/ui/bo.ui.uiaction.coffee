# Constructs a new `UI Action`, something that can be bound to in the UI using
# the `action` binding handler to execute an action when the user clicks on
# an element (e.g. a button).
#
# A UI action provides a number of benefits over just a simple function:
#
# * An action can have an associated 'enabled' status that determines whether an action
#   will be executed or not without having to wire this functionality in everytime. The
#   `action` binding handler will automatically apply attributes to the attached element
#   to allow UI feedback on the enabled status.
#
# * By using the `action` binding handler the status of execution can be automatically
#   shown to the user visually as an `executing` observable exists that keeps track of
#   the execution status of the action.
#
# * A UI action can mark itself as a 'serial' action, meaning that if the
#   action is asynchrounous the user can not execute the action multiple times in parallel,
#   which is particularly useful when submitting forms to the server.
bo.UiAction = (f) ->
    if _.isFunction f
        enabled = ko.observable true
        action = f
        serial = false
    else
        enabled = bo.utils.asObservable (f.enabled ? true)
        serial = f.serial ? false
        action = f.action

    executing = ko.observable false
        
    {
        enabled: enabled

        executing: executing

        serial: serial

        execute: ->
            if enabled() and (not serial or not executing())
                executing true
                ret = action.apply this, arguments

                if ret.then # TODO: Better way of determining a promise?
                    ret.then ->
                        executing false
                else
                    executing false

                ret
    }