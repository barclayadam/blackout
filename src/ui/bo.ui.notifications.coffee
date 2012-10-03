# Namespace that provides a number of methods for publishing notifications, 
# messages that the system can listen to to provide feedback to the user
# in a consistent fashion.
#
# All messages that are published are within the `notification` namespace, with
# the second level name being the level of notification (e.g. `notification:success`).
# The data that is passed as arguments contains:
# * `text`: The text of the notification
# * `level`: The level of the notification (i.e. `success`, `warning` or `error`)
bo.notifications =
    # Publishes a success notification, to indicate that an action
    # has completed without any warnings or failure.
    success: (text, options) ->
        bo.bus.publish 'notification:success', 
            text: text
            level: 'success'
            options: options

    # Publishes a warning notification, to indicate that an action
    # may or may not have completed but warnings exist that should
    # be looked into.
    warning: (text, options) ->
        bo.bus.publish 'notification:warning', 
            text: text
            level: 'warning'
            options: options

    # Publishes an error notification, to indicate that an
    # action has failed, that the user must either retry due to
    # an unforeseen error or that the user has peformed an action
    # illegal or invalid.
    error: (text, options) ->
        bo.bus.publish 'notification:error', 
            text: text
            level: 'error'
            options: options

# A binding handler that can be used to display notifications that are being published
# (see `bo.notifications`) to the user.
ko.bindingHandlers.notification = 
    init: (element, valueAccessor) ->
        lastNotification = undefined

        $element = jQuery element

        $element.addClass 'notification-area'
        $element.attr 'role', 'alert'
        $element.hide()

        bo.bus.subscribe 'notification', (msg) ->
            $element.removeClass lastNotification if lastNotification?

            if msg.text
                $element.addClass msg.level

                $element.text(msg.text).slideDown(350)
                setTimeout (-> $element.fadeOut()), 3500

                lastNotification = msg.level
            else
                $element.text('').hide()
            