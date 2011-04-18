vows   = require 'vows'
assert = require 'assert'

Milk = require('milk')

suite = vows.describe 'Milk.escape'

suite.addBatch
  "The exported #escape method":
    topic: -> Milk.escape

    'should perform basic HTML escaping': (esc) ->
      assert.equal(esc('Interpolated &entity;'), 'Interpolated &amp;entity;')
      assert.equal(esc('<img src="x" />'), '&lt;img src=&quot;x&quot; /&gt;')

suite.addBatch
  "Replacing the #escape method":
    topic: ->
      @escape = Milk.escape
      Milk.escape = (str) -> str.split('').reverse().join('')
      return -> Milk.render(arguments...)

    teardown: ->
      Milk.escape = @escape

    'uses the new #escape method for HTML escaping': (render) ->
      tmpl = '{{{x}}} {{x}} {{&x}}'
      data = { x: 'content' }
      assert.equal(render(tmpl, data), 'content tnetnoc content')

suite.export(module)
