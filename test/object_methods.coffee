vows   = require 'vows'
assert = require 'assert'

Milk   = require 'milk'

suite = vows.describe 'Object Methods'

suite.addBatch
  "Interpolating an object method":
    topic: -> ((data) -> Milk.render '[{{method}}]', data)

    'calls the method': (render) ->
      data = { method: -> 'a, b, c' }
      assert.equal(render(data), '[a, b, c]')

    'binds `this` to the context': (render) ->
      data = { method: (-> @data), data: 'foo' }
      assert.equal(render(data), '[foo]')

    'renders the returned string': (render) ->
      data = { method: (-> '{{data}}'), data: 'bar' }
      assert.equal(render(data), '[bar]')

  "Building a section with an object method":
    topic: -> ((data) -> Milk.render '[{{#method}}{{x}}{{/method}}]', data)

    'uses the returned string as the section content': (render) ->
      data = { method: (-> 'content') }
      assert.equal(render(data), '[content]')

    'calls the method': (render) ->
      data = { method: -> 'a, b, c' }
      assert.equal(render(data), '[a, b, c]')

    'binds `this` to the context': (render) ->
      data = { method: (-> @data), data: 'foo' }
      assert.equal(render(data), '[foo]')

    'passes the raw template string as an argument': (render) ->
      render({ method: (tmpl) -> assert.equal(tmpl, '{{x}}') })

    'renders the returned string': (render) ->
      data = { method: (-> '{{data}}'), data: 'bar' }
      assert.equal(render(data), '[bar]')

  "Using an object method in a nested context":
    topic: ->
      (tmpl, data) ->
        data = { nested: data, key: 'WRONG' }
        Milk.render "[{{#nested}}#{tmpl}{{/nested}}]", data

    "for interpolation":
      topic: (T) -> ((data) -> T('{{method}}', data))

      'calls the method': (render) ->
        data = { method: -> 'a, b, c' }
        assert.equal(render(data), '[a, b, c]')

      'binds `this` to the context element': (render) ->
        data = { method: (-> @key), key: 'foo' }
        assert.equal(render(data), '[foo]')

      'renders the returned string': (render) ->
        data = { method: (-> '{{data}}'), data: 'bar' }
        assert.equal(render(data), '[bar]')

    "for a section":
      topic: (T) -> ((data) -> T('{{#method}}{{x}}{{/method}}', data))

      'uses the returned string as the section content': (render) ->
        data = { method: (-> 'content') }
        assert.equal(render(data), '[content]')

      'calls the method': (render) ->
        data = { method: -> 'a, b, c' }
        assert.equal(render(data), '[a, b, c]')

      'binds `this` to the context element': (render) ->
        data = { method: (-> @key), key: 'foo' }
        assert.equal(render(data), '[foo]')

      'passes the raw template string as an argument': (render) ->
        render({ method: (tmpl) -> assert.equal(tmpl, '{{x}}') })

      'renders the returned string': (render) ->
        data = { method: (-> '{{data}}'), data: 'bar' }
        assert.equal(render(data), '[bar]')


suite.export(module)