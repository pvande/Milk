vows   = require 'vows'
assert = require 'assert'

Milk = require('milk')

suite = vows.describe 'Skips'

suite.addBatch
  "Skips":
    topic: ->
      data =
        name: 'A'
        useless_context: { useless: true }
        named_context:
          name: 'B'
          nested_context:
            name: 'C'
        other_context:
          name: 'D'
      tmpl = """
               "{{name}}" == "A"
               "{{name'}}" == ""

               {{#useless_context}}
               "{{name}}" == "A"
               "{{name'}}" == ""

               {{#named_context}}
               "{{name}}" == "B"
               "{{name'}}" == "A"
               "{{name''}}" == ""

               {{#useless_context}}
               "{{name}}" == "B"
               "{{name'}}" == "A"
               "{{name''}}" == ""

               {{#nested_context}}
               "{{name}}" == "C"
               "{{name'}}" == "B"
               "{{name''}}" == "A"
               "{{name'''}}" == ""

               {{#other_context}}
               "{{name}}" == "D"
               "{{name'}}" == "C"
               "{{name''}}" == "B"
               "{{name'''}}" == "A"
               "{{name''''}}" == ""

               {{#useless_context}}
               "{{name}}" == "D"
               "{{name'}}" == "C"
               "{{name''}}" == "B"
               "{{name'''}}" == "A"
               "{{name''''}}" == ""
               {{/useless_context}}
               {{/other_context}}
               {{/nested_context}}
               {{/useless_context}}
               {{/named_context}}
               {{/useless_context}}
             """
      return Milk.render(tmpl, data)

    teardown: -> Milk.helpers = []

    'should put the object on the context stack': (topic) ->
      assert.equal(topic, """
        "A" == "A"
        "" == ""

        "A" == "A"
        "" == ""

        "B" == "B"
        "A" == "A"
        "" == ""

        "B" == "B"
        "A" == "A"
        "" == ""

        "C" == "C"
        "B" == "B"
        "A" == "A"
        "" == ""

        "D" == "D"
        "C" == "C"
        "B" == "B"
        "A" == "A"
        "" == ""

        "D" == "D"
        "C" == "C"
        "B" == "B"
        "A" == "A"
        "" == ""

      """)

suite.export(module)
