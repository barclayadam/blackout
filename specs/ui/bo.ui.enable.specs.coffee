#reference "/assets/js/blackout/bo.ui.tree.coffee"

describe "enable binding handler", ->
    it 'should apply a disabled class to element when element disabled', ->
        # Arrange
        element = @setHtmlFixture '<a data-bind="enable: false" />'

        # Act
        @applyBindingsToHtmlFixture {}

        # Assert
        expect(element).toHaveClass 'disabled'

    it 'should not apply a disabled class to element when element enabled', ->
        # Arrange
        element = @setHtmlFixture '<a data-bind="enable: true" />'

        # Act
        @applyBindingsToHtmlFixture {}

        # Assert
        expect(element).toNotHaveClass 'disabled'

    it 'should update disabled class when enabled state changes', ->
        # Arrange
        shouldEnable = ko.observable true
        element = @setHtmlFixture '<a data-bind="enable: shouldEnable" />'

        @applyBindingsToHtmlFixture { shouldEnable: shouldEnable }        
        expect(element).toNotHaveClass 'disabled'

        # Act
        shouldEnable false

        # Assert
        expect(element).toHaveClass 'disabled'
      
describe "disable binding handler", ->
    it 'should apply a disabled class to element when element disabled', ->
        # Arrange
        element = @setHtmlFixture '<a data-bind="disable: true" />'

        # Act
        @applyBindingsToHtmlFixture {}

        # Assert
        expect(element).toHaveClass 'disabled'

    it 'should not apply a disabled class to element when element enabled', ->
        # Arrange
        element = @setHtmlFixture '<a data-bind="disable: false" />'

        # Act
        @applyBindingsToHtmlFixture {}

        # Assert
        expect(element).toNotHaveClass 'disabled'

    it 'should update disabled class when enabled state changes', ->
        # Arrange
        shouldDisable = ko.observable true
        element = @setHtmlFixture '<a data-bind="disable: shouldDisable" />'

        @applyBindingsToHtmlFixture { shouldDisable: shouldDisable }        
        expect(element).toHaveClass 'disabled'

        # Act
        shouldDisable false

        # Assert
        expect(element).toNotHaveClass 'disabled'