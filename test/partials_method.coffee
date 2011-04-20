vows   = require 'vows'
assert = require 'assert'

Milk = require('milk')

suite = vows.describe 'Milk.escape'

suite.addBatch
  "Supplying a #partials method":
    topic: ->
      @partials = Milk.partials
      Milk.partials = (str) -> str.split('').reverse().join('')
      return -> Milk.render(arguments...)

    teardown: ->
      Milk.partials = @partials

    'provides a new default Partial resolution mechanism': (render) ->
      tmpl = '[{{>partial_name}}]'
      data = { }
      assert.equal(render(tmpl, data), '[eman_laitrap]')

    'can be overridden by supplying a partial hash to #render': (render) ->
      tmpl = '[{{>partial_name}}]'
      data = { }
      partials =
        partial_name: 'from hash'
      assert.equal(render(tmpl, data, partials), '[from hash]')

      render_missing_partial = -> render('{{>miss}}', data, partials)
      assert.throws(render_missing_partial, /^Unknown partial 'miss'!$/)

suite.export(module)
