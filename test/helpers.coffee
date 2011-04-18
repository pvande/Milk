vows   = require 'vows'
assert = require 'assert'

Milk = require('milk')

suite = vows.describe 'Milk.helpers'

suite.addBatch
  "Providing an object to Milk.helpers":
    topic: ->
      Milk.helpers = { key: 'helper', helper: 'helper' }
      return -> Milk.render(arguments...)

    teardown: -> Milk.helpers = []

    'should put the object on the context stack': (render) ->
      result = render('[{{helper}}, {{data}}]', { data: 'data' })
      assert.equal(result, '[helper, data]')

    'should put the object at the bottom of the context stack': (render) ->
      result = render('[{{helper}}, {{key}}]', { key: 'data' })
      assert.equal(result, '[helper, data]')

suite.addBatch
  "Providing an array to Milk.helpers":
    topic: ->
      Milk.helpers = [{ key: 'helper', helper: 'helper' }, { helper: 'two' }]
      return -> Milk.render(arguments...)

    teardown: -> Milk.helpers = []

    'should put each element on the context stack': (render) ->
      result = render('[{{key}}, {{data}}]', { data: 'data' })
      assert.equal(result, '[helper, data]')

    'should put each element on the context stack in order': (render) ->
      result = render('[{{key}}, {{helper}}]', { })
      assert.equal(result, '[helper, two]')

    'should put the elements at the bottom of the context stack': (render) ->
      result = render('[{{helper}}, {{key}}]', { key: 'data' })
      assert.equal(result, '[two, data]')

suite.export(module)
