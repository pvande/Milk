# Milk is a simple, fast way to get more Mustache into your CoffeeScript and
# Javascript.
#
# Mustache templates are reasonably simple -- plain text templates are
# sprinkled with "tags", which are (by default) a pair of curly braces
# surrounding some bit of content. A good resource for Mustache can be found
# [here](mustache.github.com).
TemplateCache = {}

# Tags used for working with data get their data by looking up a name in a
# context stack. This name corresponds to a key in a hash, and the stack is
# searched top to bottom for an object with given key. Dots in names are
# special: a single dot ('.') is "top of stack", and dotted names like 'a.b.c'
# do a chained lookups.
Find = (name, stack, value = null) ->
  return stack[stack.length - 1] if name == '.'
  [name, parts...] = name.split(/\./)
  for i in [stack.length - 1...-1]
    continue unless stack[i]?
    continue unless typeof stack[i] == 'object' and name of (ctx = stack[i])
    value = ctx[name]
    break

  value = Find(part, [value]) for part in parts

  # If we find a function in the stack, we'll treat it as a method, and call it
  # with `this` bound to the element it came from. If a method returns a
  # function, we treat it as a lambda, which doesn't have a bound `this`.
  if value instanceof Function
    value = do (value) -> ->
      val = value.apply(ctx, arguments)
      return (val instanceof Function) and val.apply(null, arguments) or val

  # Null values will be coerced to the empty string.
  return value

# Parsed templates are expanded by simply calling each function in turn.
Expand = (obj, tmpl, args...) -> (f.call(obj, args...) for f in tmpl).join('')

# For parsing, we'll basically need a template string to parse. We do need to
# remember to take the tag delimiters into account for the cache -- different
# parse trees can exist for the same template string!
Parse = (template, delimiters = ['{{','}}'], section = null) ->
  cache = (TemplateCache[delimiters.join(' ')] ||= {})
  return cache[template] if template of cache

  buffer = []

  # We'll use a regular expression to handle tag discovery. A proper parser
  # might be faster, but this is simpler, and certainly fast enough for now.
  # Since the tag delimiters may change over time, we'll want to rebuild the
  # regex when they change.
  BuildRegex = ->
    [tagOpen, tagClose] = delimiters
    return ///
      ([\s\S]*?)                # Capture the pre-tag content
      ([#{' '}\t]*)             # Capture the pre-tag whitespace
      (?: #{tagOpen} \s*        # Match the opening tag
      (?:
        (!)                  \s* ([\s\S]+?)       | # Comments
        (=)                  \s* ([\s\S]+?) \s* = | # Set Delimiters
        ({)                  \s* (\w[\S]*?) \s* } | # Triple Mustaches
        ([^0-9a-zA-Z._!={]?) \s* ([\w.][\S]*?)      # Everything else
      )
      \s* #{tagClose} )         # Match the closing tag
    ///gm

  tagPattern = BuildRegex()
  tagPattern.lastIndex = pos = (section || { start: 0 }).start

  # Useful errors should always be prefered - we should compile as much
  # relevant information as possible.
  parseError = (pos, msg) ->
    (endOfLine = /$/gm).lastIndex = pos
    endOfLine.exec(template)

    parsedLines = template.substr(0, pos).split('\n')
    lineNo      = parsedLines.length
    lastLine    = parsedLines[lineNo - 1]
    tagStart    = contentEnd + whitespace.length
    lastTag     = template.substr(tagStart + 1, pos - tagStart - 1)

    indent   = new Array(lastLine.length - lastTag.length + 1).join(' ')
    carets   = new Array(lastTag.length + 1).join('^')
    lastLine = lastLine + template.substr(pos, endOfLine.lastIndex - pos)

    error = new Error()
    error[key] = e[key] for key of e =
      "message": "#{msg}\n\nLine #{lineNo}:\n#{lastLine}\n#{indent}#{carets}"
      "error": msg, "line": lineNo, "char": indent.length, "tag": lastTag
    return error

  # As we start matching things, let's pull out our captures and build indices.
  while match = tagPattern.exec(template)
    [content, whitespace] = match[1..2]
    type = match[3] || match[5] || match[7] || match[9]
    tag  = match[4] || match[6] || match[8] || match[10]

    contentEnd = (pos + content.length) - 1
    pos        = tagPattern.lastIndex

    # Standalone tags are tags on lines without any non-whitespace characters.
    isStandalone = (contentEnd == -1 or template.charAt(contentEnd) == '\n') &&
                   template.charAt(pos) in [ undefined, '', '\r', '\n' ]

    # We should just add static content to the buffer.
    buffer.push(do (content) -> -> content) if content

    # If we're dealing with a standalone tag that's not interpolation, we
    # should consume the newline immediately following the tag. If we're not,
    # we need to buffer the whitespace we captured earlier.
    if isStandalone and type not in ['', '&', '{']
      pos += 1 if template.charAt(pos) == '\r'
      pos += 1 if template.charAt(pos) == '\n'
    else if whitespace
      buffer.push(do (whitespace) -> -> whitespace)
      contentEnd += whitespace.length
      whitespace = ''

    # Now we'll handle the tag itself:
    switch type

      # Comment tags should simply be ignored.
      when '!' then break

      # Interpolations are handled by finding the value in the context stack,
      # calling and rendering lambdas, and escaping the value if appropriate.
      when '', '&', '{'
        buildInterpolationTag = (name, is_unescaped) ->
          return (context) ->
            if (value = Find(name, context) ? '') instanceof Function
              value = Expand(this, Parse("#{value()}"), arguments...)
            value = @escape("#{value}") unless is_unescaped
            return "#{value}"
        buffer.push(buildInterpolationTag(tag, type))

      # Partial data is looked up lazily by the given function, indented as
      # appropriate, and then rendered.
      when '>'
        buildPartialTag = (name, indentation) ->
          return (context, partials) ->
            partial = partials(name).toString()
            partial = partial.replace(/^(?=.)/gm, indentation) if indentation
            return Expand(this, Parse(partial), arguments...)
        buffer.push(buildPartialTag(tag, whitespace))

      # Sections and Inverted Sections make a recursive parsing pass, allowing
      # us to use the call stack to handle section parsing. This will go until
      # it reaches the matching End Section tag, when it will return the
      # (cached!) template it parsed, along with the index it stopped at.
      when '#', '^'
        sectionInfo =
          name: tag, start: pos
          error: parseError(tagPattern.lastIndex, "Unclosed section '#{tag}'!")
        [tmpl, pos] = Parse(template, delimiters, sectionInfo)

        # Sections are rendered by finding the value in the context stack,
        # coercing it into an array (unless the value is falsey), and rendering
        # the template with each element of the array taking a turn atop the
        # context stack. If the value was a function, the template is filtered
        # through it before rendering.
        sectionInfo['#'] = buildSectionTag = (name, delims, raw) ->
          return (context) ->
            value = Find(name, context) || []
            tmpl  = if value instanceof Function then value(raw) else raw
            value = [value] unless value instanceof Array
            parsed = Parse(tmpl || '', delims)

            context.push(value)
            result = for v in value
              context[context.length - 1] = v
              Expand(this, parsed, arguments...)
            context.pop()

            return result.join('')

        # Inverted Sections render under almost opposite conditions: their
        # contents will only be rendered when the retrieved value is either
        # falsey or an empty array.
        sectionInfo['^'] = buildInvertedSectionTag = (name, delims, raw) ->
          return (context) ->
            value = Find(name, context) || []
            value = [1] unless value instanceof Array
            value = if value.length is 0 then Parse(raw, delims) else []
            return Expand(this, value, arguments...)

        buffer.push(sectionInfo[type](tag, delimiters, tmpl))

      # When the parser encounters an End Section tag, it runs a couple of
      # quick sanity checks, then returns control back to its caller.
      when '/'
        unless section?
          error = "End Section tag '#{tag}' found, but not in section!"
        else if tag != (name = section.name)
          error = "End Section tag closes '#{tag}'; expected '#{name}'!"
        throw parseError(tagPattern.lastIndex, error) if error

        template = template[section.start..contentEnd]
        cache[template] = buffer
        return [template, pos]

      # The Set Delimiters tag needs to update the delimiters after some error
      # checking, and rebuild the regular expression we're using to match tags.
      when '='
        unless (delimiters = tag.split(/\s+/)).length == 2
          error = "Set Delimiters tags should have two and only two values!"
        throw parseError(tagPattern.lastIndex, error) if error

        escape     = /[-[\]{}()*+?.,\\^$|#]/g
        delimiters = (d.replace(escape, "\\$&") for d in delimiters)
        tagPattern = BuildRegex()

      # Any other tag type is probably a typo.
      else
        throw parseError(tagPattern.lastIndex, "Unknown tag type -- #{type}")

    # Now that we've finished with this tag, we prepare to parse the next one!
    tagPattern.lastIndex = if pos? then pos else template.length

  # At this point, we've parsed all the tags.  If we've still got a `section`,
  # someone left a section tag open.
  throw section.error if section?

  # All the tags is not all the content; if there's anything left over, append
  # it to the buffer.  Then we'll cache the buffer and return it!
  buffer.push(-> template[pos..]) unless template.length == pos
  return cache[template] = buffer

# ### Public API

# The exported object (globally `Milk` in browsers) forms Milk's public API:
Milk =
  VERSION: '1.2.0'
  # Helpers are a form of context, implicitly on the bottom of the stack. This
  # is a global value, and may be either an object or an array.
  helpers:  []
  # Partials may also be provided globally.
  partials: null
  # The `escape` method performs basic content escaping, and may be either
  # called or overridden with an alternate escaping mechanism.
  escape: (value) ->
    entities = { '&': 'amp', '"': 'quot', '<': 'lt', '>': 'gt' }
    return value.replace(/[&"<>]/g, (ch) -> "&#{ entities[ch] };")
  # Rendering is simple: given a template and some data, it populates the
  # template. If your template uses Partial Tags, you may also supply a hash or
  # a function, or simply override `Milk.partials`. There is no Step Three.
  render: (template, data, partials = null) ->
    unless (partials ||= @partials || {}) instanceof Function
      partials = do (partials) -> (name) ->
        throw "Unknown partial '#{name}'!" unless name of partials
        return Find(name, [partials])

    context = if @helpers instanceof Array then @helpers else [@helpers]
    return Expand(this, Parse(template), context.concat([data]), partials)

# Happy hacking!
if exports?
  exports[key] = Milk[key] for key of Milk
else
  this.Milk = Milk
