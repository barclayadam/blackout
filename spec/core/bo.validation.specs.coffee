describe 'validation', ->
    describe 'given a plain object', ->
        describe 'when making it validatable (mixin)', ->
            beforeEach ->
                @model = {}

                bo.validation.mixin @model

            it 'should add a validate method', ->
                expect(@model.validate).toBeAFunction()

            it 'should add an isValid observable set to undefined', ->
                expect(@model.isValid).toBeObservable()
                expect(@model.isValid()).toBeUndefined()

            it 'should add a validated observable set to false', ->
                expect(@model.validated).toBeObservable()
                expect(@model.validated()).toBe false

    describe 'given a plain observable', ->
        describe 'when making it validatable (mixin)', ->
            beforeEach ->
                @property = ko.observable()
                @property.addValidationRules { required: true }

            it 'should add a validate method', ->
                expect(@property.validate).toBeAFunction()

            it 'should add an isValid observable immediately set to correct state', ->
                expect(@property.isValid).toBeObservable()
                expect(@property.isValid()).toEqual false

            it 'should add a validated observable set to false', ->
                expect(@property.validated).toBeObservable()
                expect(@property.validated()).toBe false

            describe 'updating invalid property to be valid', ->
                beforeEach ->
                    @property 'My Required Value'

                it 'should remove any errors to the errors property', ->
                    expect(@property.errors().length).toEqual 0

                it 'should mark the property as valid', ->
                    expect(@property.isValid()).toEqual true

    describe 'validating a property', ->
        beforeEach ->
            @property = ko.observable()
            @property.addValidationRules { required: true }

            @property.validate()

        it 'should mark property as being validated', ->
            expect(@property.validated()).toBe true


    describe 'adding validation rules multiple times', ->
        beforeEach ->
            @property = ko.observable('a')
            @property.addValidationRules { minLength: 2 }
            @property.addValidationRules { equalTo: 'b' }

        it 'should include errors for each added rule', ->
            expect(@property.errors().length).toBe 2

    describe 'validating a model', ->
        describe 'with no defined observable properties', ->
            beforeEach ->
                @model = {}
                bo.validation.mixin @model

                @model.validate()

            it 'should set isValid to true', ->
                expect(@model.isValid()).toBe true

            it 'should set validated observable to true', ->
                expect(@model.validated()).toBe true

        describe 'with validatable properties', ->
            createModel = (values) ->
                model = 
                    property1: ko.observable(values.property1).addValidationRules
                        required: true

                    property2: ko.observable(values.property2).addValidationRules
                        required: true
                        requiredMessage: 'This is a custom message'

                bo.validation.mixin model
                model.validate()

                model

            describe 'when all properties are valid', ->
                beforeEach ->
                    @model = createModel 
                        property1: 'A Value'
                        property2: 'A Value'

                it 'should set isValid to true', ->
                    expect(@model.isValid()).toBe true

                it 'should set validated observable to true', ->
                    expect(@model.validated()).toBe true

            describe 'when single property is invalid', ->
                beforeEach ->
                    @model = createModel 
                        property1: 'A Value'

                it 'should set isValid of the model to false', ->
                    expect(@model.isValid()).toBe false

                it 'should set validated observable to true', ->
                    expect(@model.validated()).toBe true

                it 'should not add error message to errors property of valid observable', ->
                    expect(@model.property1.errors().length).toBe 0

                it 'should set isValid to true for the valid property', ->
                    expect(@model.property1.isValid()).toBe true

                it 'should add error message to errors property of invalid observable', ->
                    expect(@model.property2.errors().length).toBe 1

                it 'should set isValid to false for the invalid property', ->
                    expect(@model.property2.isValid()).toBe false

                it 'should use custom message if specified', ->
                    expect(@model.property2.errors()[0]).toEqual 'This is a custom message'

            describe 'when values are updated to make them valid', ->
                beforeEach ->
                    @model = createModel 
                        property1: 'A Value'

                    @model.property2 'A Value'

                it 'should set isValid of the model to true', ->
                    expect(@model.isValid()).toBe true

                it 'should set isValid to true for the now valid property', ->
                    expect(@model.property2.isValid()).toBe true

                it 'should remove error message from the invalid observable', ->
                    expect(@model.property2.errors().length).toBe 0

                it 'should set isValid to true for the now valid property', ->
                    expect(@model.property2.isValid()).toBe true

            describe 'when multiples properties are invalid', ->
                beforeEach ->
                    @model = createModel {}

                it 'should set isValid of the model to false', ->
                    expect(@model.isValid()).toBe false

                it 'should add error messages to errors property of all invalid observable', ->
                    expect(@model.property1.errors().length).toBe 1
                    expect(@model.property2.errors().length).toBe 1

                it 'should set isValid to false for all inalid properties', ->
                    expect(@model.property1.isValid()).toBe false
                    expect(@model.property2.isValid()).toBe false

            describe 'when array property has no validationRules', ->
                beforeEach ->
                    @model = createModel 
                        property1: 'A Value' # To make valid
                        property2: []

                it 'should set isValid to true', ->
                    expect(@model.isValid()).toBe true

            describe 'when array property has validationRules that are broken', ->
                beforeEach ->
                    @model = 
                        arrayProp: ko.observable([]).addValidationRules
                            minLength: 2

                    bo.validation.mixin @model

                    @model.validate()

                it 'should set isValid of the model to false', ->
                    expect(@model.isValid()).toBe false

                it 'should set isValid of the array property to false', ->
                    expect(@model.arrayProp.isValid()).toBe false

                it 'should add error message to the array property error observable', ->
                    expect(@model.arrayProp.errors().length).toBe 1

                describe 'and child validatables with one failing', ->
                    beforeEach ->
                        makeArrayValue = (value) ->
                            ko.observable(value).addValidationRules
                                required: true

                        array = [
                            makeArrayValue('A Value'),
                            makeArrayValue(undefined),
                            makeArrayValue('Another Value')
                        ]

                        @model = 
                            arrayProp: ko.observable(array).addValidationRules
                                minLength: 2

                        bo.validation.mixin @model

                        @model.validate()

                    it 'should set isValid of the model to false', ->
                        expect(@model.isValid()).toBe false

                    it 'should set isValid of the valid child array property to true', ->
                        expect(@model.arrayProp()[0].isValid()).toBe true
                        expect(@model.arrayProp()[2].isValid()).toBe true

                    it 'should set isValid of the invalid child array property to false', ->                    
                        expect(@model.arrayProp()[1].isValid()).toBe false

            describe 'when array property has child validatables with one failing', ->
                beforeEach ->
                    makeArrayValue = (value) ->
                        ko.observable(value).addValidationRules
                            required: true

                    array = [
                        makeArrayValue('A Value'),
                        makeArrayValue(undefined),
                        makeArrayValue('Another Value')
                    ]

                    @model = bo.validation.newModel
                        arrayProp: ko.observable(array)

                    @model.validate()

                it 'should set isValid of the model to false', ->
                    expect(@model.isValid()).toBe false

                it 'should set isValid of the valid child array property to true', ->
                    expect(@model.arrayProp()[0].isValid()).toBe true
                    expect(@model.arrayProp()[2].isValid()).toBe true

                it 'should set isValid of the invalid child array property to false', ->                    
                    expect(@model.arrayProp()[1].isValid()).toBe false

            describe 'when plain child object has validatables with one failing', ->
                beforeEach ->
                    @model = 
                        child:
                            childProperty: ko.observable().addValidationRules
                                required: true

                    bo.validation.mixin @model

                    @model.validate()

                it 'should set isValid of the model to false', ->
                    expect(@model.isValid()).toBe false

                it 'should set isValid of the invalid child property to false', ->
                    expect(@model.child.childProperty.isValid()).toBe false

            describe 'when observable child object has validatables with one failing', ->
                beforeEach ->
                    child = 
                        childProperty: ko.observable().addValidationRules
                            required: true

                    @model = 
                        child: ko.observable(child)

                    bo.validation.mixin @model

                    @model.validate()

                it 'should set isValid of the model to false', ->
                    expect(@model.isValid()).toBe false

                it 'should set isValid of the invalid child property to false', ->
                    expect(@model.child().childProperty.isValid()).toBe false

            describe 'when only server-side errors are set', ->
                beforeEach ->
                    # Creates a client-side valid model
                    @model = createModel 
                        property1: 'A Value'
                        property2: 'A Value'

                    @model.setServerErrors
                        property1: 'property1 is invalid on server',
                        _: 'The whole form is somehow invalid'

                it 'should set isValid to true', ->
                    expect(@model.isValid()).toBe true

                it 'should set non-property error messages on serverErrors of model', ->
                    expect(@model.serverErrors()).toEqual ['The whole form is somehow invalid']

                it 'should set property error messages on serverErrors of property', ->
                    expect(@model.property1.serverErrors()).toEqual ['property1 is invalid on server']

                it 'should set isValid of property with server-side errors to true', ->
                    expect(@model.property1.isValid()).toBe true

                describe 'and property value is updated', ->
                    beforeEach ->
                        @model.property1 'A New Value'

                    it 'should clear the server errors of the property', ->
                        expect(@model.property1.serverErrors()).toBeAnEmptyArray()

                describe 'and model is validated again', ->
                    beforeEach ->
                        @model.validate()

                    it 'should clear the server errors of the model', ->
                        expect(@model.serverErrors()).toBeAnEmptyArray()

        describe 'messaging', ->
            beforeEach ->
                bo.validation.rules.myCustomRule =
                    validator: ->
                        false

                    message: @stub().returns 'myCustomRule message'

                @model =
                    customMessageProp: ko.observable().addValidationRules 
                        required: true
                        requiredMessage: 'My custom failure message'

                    customPropertyNameProp: ko.observable().addValidationRules 
                        required: true
                        propertyName: 'myOverridenPropertyName'

                    customRuleProp: ko.observable().addValidationRules 
                        myCustomRule: true

                bo.validation.mixin @model
                @model.validate()

            it 'should use message specified in rules', ->
                expect(@model.customMessageProp.errors()).toContain 'My custom failure message'

            it 'should call rule message property if no overrides', ->
                expect(bo.validation.rules.myCustomRule.message).toHaveBeenCalledWith true

            it 'should not format error messages by default', ->
                expect(@model.customRuleProp.errors()).toContain 'myCustomRule message'