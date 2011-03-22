vows   = require 'vows'
assert = require 'assert'

Milk = require('milk')

suite = vows.describe 'Milk.escape'

suite.addBatch
  "If the `partials` parameter is":
    topic: ->
      return (partials) -> (tmpl, data) -> Milk.render(tmpl, data, partials)

    "a hash":
      topic: (parent) ->
        return parent({ partial_name: 'from hash' })

      'lookups by name work properly': (render) ->
        tmpl = '[{{>partial_name}}]'
        assert.equal(render(tmpl, { }), '[from hash]')

      'lookups that fail throw an error': (render) ->
        render_missing_partial = -> render('{{>miss}}', { })
        assert.throws(render_missing_partial, /^Unknown partial 'miss'!$/)

    "a function":
      topic: (parent) ->
        return parent((name) -> name.split('').reverse().join(''))

      'lookups are handled by that function': (render) ->
        tmpl = '[{{>partial_name}}]'
        data = { }
        assert.equal(render(tmpl, data), '[eman_laitrap]')

suite.export(module)
