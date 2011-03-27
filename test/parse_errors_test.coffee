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
      assert.match(e.toString(), ///^#{error.message}///m)
      return
    assert.ok(false, "Did not throw error!")
  'gives the correct line number in the thrown error': (render) ->
    try
      render()
    catch e
      assert.equal(e.line, error.line)
      return
    assert.ok(false, "Did not throw error!")
  'gives the correct character number in the thrown error': (render) ->
    try
      render()
    catch e
      assert.equal(e.char, error.character)
      return
    assert.ok(false, "Did not throw error!")
  'gives the correct errorful tag in the thrown error': (render) ->
    try
      render()
    catch e
      assert.equal(e.tag, error.tag)
      return
    assert.ok(false, "Did not throw error!")

suite = vows.describe 'Parse Errors'

suite.addBatch
  "Closing the wrong section tag":
    throwsError(
      {
        message: "Error: End Section tag closes 'other'; expected 'section'!"
        line: 4
        character: 0
        tag: '{{/other}}'
      },
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
      {
        message: "Error: End Section tag closes 'a'; expected 'b'!"
        line: 3
        character: 0
        tag: '{{/a}}'
      },
      '''
        {{#a}}
          {{#b}}
        {{/a}}
      '''
    )

  "Closing a section at the top level":
    throwsError(
      {
        message: "Error: End Section tag 'section' found, but not in section!"
        line: 2
        character: 0
        tag: '{{/section}}'
      },
      '''
        Before...
        {{/section}}
        After...
      '''
    )

  "Failing to close a top-level section":
    throwsError(
      {
        message: "Error: Unclosed section 'section'!"
        line: 2
        character: 0
        tag: '{{# section }}'
      },
      '''
        Before...
        {{# section }}
        After...
      '''
    )

  "Failing to close an indented top-level section":
    throwsError(
      {
        message: "Error: Unclosed section 'section'!"
        line: 2
        character: 2
        tag: '{{# section }}'
      },
      '''
        Before...
          {{# section }}
        After...
      '''
    )

  "Specifying too few delimiters":
    throwsError(
      {
        message: "Error: Set Delimiters tags should have two and only two values!"
        line: 1
        character: 0
        tag: '{{= $$$ =}}'
      },
      '{{= $$$ =}}'
    )

  "Specifying too many delimiters":
    throwsError(
      {
        message: "Error: Set Delimiters tags should have two and only two values!"
        line: 1
        character: 0
        tag: '{{= $ $ $ =}}'
      },
      '{{= $ $ $ =}}'
    )

  "Specifying an unknown tag type":
    throwsError(
      {
        message: "Error: Unknown tag type -- §"
        line: 1
        character: 0
        tag: '{{§ something }}'
      },
      '{{§ something }}'
    )

  "Specifying an errorful tag at the beginning of the line":
    throwsError(
      {
        message: "[^]{10}$"
        line: 1
        character: 0
        tag: '{{$ tag }}'
      },
      '{{$ tag }} is over here...'
    )

  "Specifying an errorful tag further in on a line":
    throwsError(
      {
        message: "    [^]{10}$"
        line: 1
        character: 4
        tag: '{{$ tag }}'
      },
      'Now {{$ tag }} is over here...'
    )

  "Specifying an errorful tag amongst valid tags on the same line":
    throwsError(
      {
        message: "                                   [^]{10}"
        line: 1
        character: 35
        tag: '{{$ tag }}'
      },
      'Yes, this is a {{ tag }}, but this {{$ tag }} is {{invalid}}.'
    )

  "Specifying an errorful tag amongst valid tags on different lines":
    throwsError(
      {
        message: 'This [{]{2}[$] tag [}]{2} has an error$'
        line: 2
        character: 5
        tag: '{{$ tag }}'
      },
      '''
        This is a {{tag}}
        This {{$ tag }} has an error
        This one is {{ fine }}
      '''
    )

suite.export(module)