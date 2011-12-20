# reference "bo.coffee"
# reference "bo.utils.coffee"

bo.utils.addTemplate 'printItemTemplate', '''
        <tr>
            <td style="padding: 2px 4px 0 0; color: #000"><span data-bind="text: key" />:</td>
            <td style="padding: 0 0 0 4px" data-bind="output: value" />
        </tr>
        '''

bo.utils.addTemplate 'objectTemplate', '''
        <table class="bo-pretty-print">
            <tbody data-bind="template: { name : 'printItemTemplate', foreach: properties }" />
        </table>
        '''

getType = (v) ->
  return "null"  if v == null
  return "undefined"  if v == undefined
  return "domelement"  if v.nodeType and v.nodeType == 1
  return "domnode" if v.nodeType
  oType = Object::toString.call(v).match(/\s(.+?)\]/)[1].toLowerCase()
  return oType  if /^(string|number|array|regexp|function|date|boolean)$/.test oType
  return "jquery" if v.jquery
  
  "object"

simpleHandler = (element, value, color = '#000') ->
    jQuery(element).html "<span style='color: #{color}'>#{value}</span>"
    
handlers =
    array: (element, value) ->
        if value.length is 0
            simpleHandler element, '[]'
        else
            properties = []
            properties.push { key: "[#{propKey}]", value: ko.utils.unwrapObservable propValue } for own propKey, propValue of value

            ko.renderTemplate "objectTemplate", { properties: properties }, {}, element, "replaceChildren"

    object: (element, value) ->
        if jQuery.isEmptyObject value
            simpleHandler element, '{}'
        else
            properties = []
            properties.push { key: propKey, value: ko.utils.unwrapObservable propValue } for own propKey, propValue of value

            ko.renderTemplate "objectTemplate", { properties: properties }, {}, element, "replaceChildren"                

    string:  (element, value) ->
        simpleHandler element, '"' + value + '"', '#080'

    number:  (element, value) ->
        simpleHandler element, value

    regexp:  (element, value) ->
        simpleHandler element, value.toString(), '#080'

    function:  (element, value) ->
        simpleHandler element, "[function]"

    date:  (element, value) ->
        simpleHandler element, value

    boolean:  (element, value) ->
        simpleHandler element, value, '#008'

    domelement:  (element, value) ->
        id = value.id || '[none]'
        simpleHandler element, "DOM Element: &lt;#{value.nodeName.toLowerCase()} id='#{id}' /&gt;"

    domnode:  (element, value) ->
        simpleHandler element, "DOM Node of type #{value.nodeType}"

    null:  (element, value) ->
        simpleHandler element, 'null', '#008'

    undefined:  (element, value) ->
        simpleHandler element, 'undefined', '#008'

    jquery:  (element, value) ->
        simpleHandler element, "jQuery(<span style='color: #080'>'#{value.selector}'</span>)"

ko.bindingHandlers.output =
    init: ->
        { "controlsDescendantBindings": true }

    update: (element, valueAccessor) ->
        value = ko.utils.unwrapObservable valueAccessor()

        handlers[getType value] element, value
