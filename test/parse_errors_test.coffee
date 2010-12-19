vows   = require 'vows'
assert = require 'assert'

Milk   = require 'milk'

throwsError = (error, tmpl) ->
  topic: -> (-> Milk.render tmpl)
  'throws an error': (render) ->
    assert.throws(render)
  'throws expected error': (render) ->
    try
      render()
    catch e
      assert.match(e, ///^#{error}///)
      return
    assert.ok(false, "Did not throw error!")

suite = vows.describe 'Parse Errors'

suite.addBatch
  "Closing the wrong section tag":
    throwsError(
      "End Section tag closes 'other'; expected 'section'!",
      '''
        Before...
        {{#section}}
        Inner...
        {{/other}}
        After...
      '''
    )

  "Not closing a nested section tag":
    throwsError(
      "End Section tag closes 'a'; expected 'b'!",
      '''
        {{#a}}
          {{#b}}
        {{/a}}
      '''
    )

  "Closing a section at the top level":
    throwsError(
      "End Section tag 'section' found, but not in section!",
      '''
        Before...
        {{/section}}
        After...
      '''
    )

  "Specifying too few delimiters":
    throwsError(
      "Set Delimiters tags should have two and only two values!",
      '{{= $$$ =}}'
    )

  "Specifying too many delimiters":
    throwsError(
      "Set Delimiters tags should have two and only two values!",
      '{{= $ $ $ =}}'
    )

  "Specifying an unknown tag type":
    throwsError(
      "Unknown tag type -- §",
      '{{§ something }}'
    )

suite.export(module)