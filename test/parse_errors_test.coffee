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
      assert.match(e, ///^#{error}///m)
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

  "Indicating the tag":
    throwsError(
      "[^]{10}$",
      '{{$ tag }} is over here...'
    )

  "Indicating a tag further in":
    throwsError(
      "    [^]{10}$",
      'Now {{$ tag }} is over here...'
    )

  "Indicating the correct tag":
    throwsError(
      "                                   [^]{10}",
      'Yes, this is a {{ tag }}, but this {{$ tag }} is {{invalid}}.'
    )

  "Indicating the correct line":
    throwsError(
      'This [{]{2}[$] tag [}]{2} has an error$',
      '''
        This is a {{tag}}
        This {{$ tag }} has an error
        This one is {{ fine }}
      '''
    )

  "Indicating the correct tag on the correct line":
    throwsError(
      "     [^]{10}$",
      '''
        This is a {{tag}}
        This {{$ tag }} has an error
        This one is {{ fine }}
      '''
    )

suite.export(module)