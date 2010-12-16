# Milk is a simple, fast way to get more Mustache into your CoffeeScript and
# Javascript.
#
# Plenty of good resources for Mustache can be found
# [here](mustache.github.com), so little will be said about the templating
# language itself here.
#
# Template rendering is broken into a couple of distinct phases: deconstructing
# a parse tree, and generating the final result.

#### Parsing

# Mustache templates are reasonably simple -- plain text templates are
# sprinkled with "tags", which are (by default) a pair of curly braces
# surrounding some bit of content.
[tagOpen, tagClose] = ['{{', '}}']

# We're going to take the easy route this time, and just match away large parts
# of the template with a regular expression.  This isn't likely the fastest
# approach, but it is fairly simple.
# Since the tag delimiters can change over time, we'll need to rebuild the
# regex when they change.
BuildRegex = ->
  return ///
    ((?:.|\n)*?)               # Capture the pre-tag content
    ([#{' '}\t]*)              # Capture the pre-tag whitespace
    (?:#{tagOpen} \s*)         # Match the opening tag
    (?:
      (=)   \s* (.+?) \s* = |  # Capture type and content for Set Delimiters
      ({)   \s* (.+?) \s* } |  # Capture type and content for Triple Mustaches
      (\W?) \s* ((?:.|\n)+?)   # Capture type and content for everything else
    )
    (?:\s* #{tagClose})        # Match the closing tag
  ///gm

# In the simplest case, we'll simply need a template string to parse.  If we've
# parsed this template before, the cache will let us bail early.
TemplateCache = {}

Parse = (template, sectionName = null, templateStart = 0) ->
  return TemplateCache[template] if template of TemplateCache

  buffer = []

  tagPattern = BuildRegex()
  tagPattern.lastIndex = pos = templateStart

  # As we start matching things, we'll pull out the relevant captures, indices,
  # and deterimine whether the tag is standalone.
  while match = tagPattern.exec(template)
    [content, whitespace] = match[1..2]
    type = match[3] || match[5] || match[7]
    tag  = match[4] || match[6] || match[8]

    contentEnd = (pos + content.length) - 1
    pos        = tagPattern.lastIndex

    isStandalone = template[contentEnd] in [ undefined, '\n' ] and
                   template[pos]        in [ undefined, '\n' ]

    # Append the static content to the buffer.
    buffer.push content

    # If we're dealing with a standalone non-interpolation tag, we should skip
    # over the newline immediately following the tag.  If we're not, we need
    # give back the whitespace we've been holding hostage.
    if isStandalone and type not in ['', '&', '{']
      pos += 1
    else if whitespace
      buffer.push(whitespace)
      whitespace = ''

    # Next, we'll handle the tag itself:
    switch type

      # Comment tags should simply be ignored.
      when '!' then break

      # Interpolation tags only require the tag name.
      when '', '&', '{' then buffer.push [ type, tag ]

      # Partial will require the tag name and any leading whitespace, which
      # will be used to indent the partial.
      when '>' then buffer.push [ type, tag, whitespace ]

      # Sections and Inverted Sections make a recursive call to `Parse`,
      # starting immediately after the tag.  This call will continue to walk
      # through the template until it reaches an End Section tag, when it will
      # return the subtemplate it's parsed (and cached!) and the index after
      # the End Section tag.  We'll save the tag name and subtemplate string.
      when '#', '^'
        [tmpl, pos] = Parse(template, tag, pos)
        buffer.push [ type, tag, tmpl ]

      when '/'
        template = template[templateStart..contentEnd]
        TemplateCache[template] = buffer
        return [template, pos]

      # The Set Delimeters tag doesn't actually generate output, but instead
      # changes the tagPattern that the parser uses.  All delimeters need to be
      # regex escaped for safety.
      when '='
        [tagOpen, tagClose] = for delim in tag.split(/\s+/)
          delim.replace(/[-[\]{}()*+?.,\\^$|#]/g, "\\$&")
        tagPattern = BuildRegex()

      else throw "Unknown tag type -- #{type}"

    # And finally, we'll advance the tagPattern's lastIndex (so that it resumes
    # parsing where we intend it to), and loop.
    tagPattern.lastIndex = pos

  # When we've exhausted all of the matches for tagPattern, we'll still have a
  # small portion of the template remaining.  We'll append it to the buffer,
  # cache it, and return the buffer!
  buffer.push(template[pos..])
  return TemplateCache[template] = buffer

escape = (value) ->
  escapes = { '&': 'amp', '"': 'quot', '<': 'lt', '>': 'gt' }
  return value.replace(/[&"<>]/g, (c) -> "&#{escapes[c]};")

find = (name, stack) ->
  for i in [stack.length - 1...-1]
    ctx = stack[i]
    continue unless name of ctx
    value = ctx[name]
    return switch typeof value
      when 'undefined' then ''
      when 'function'  then value()
      else value
  return ''

Generate = (parsed, data, context = []) ->
  context.push data if data.constructor is Object
  (handle(part, context) for part in parsed).join('')

handle = (part, context) ->
  return part if typeof part is 'string'
  switch part[0]
    when '>'
      [_, name, indent] = part
      throw "Meaningful error message" unless name of Partials
      partial = Parse(Partials[name])
      content = Generate(partial, {}, context)
      content = content.replace(/^(?=.)/gm, indent) if indent
      return content
    when '#'
      [_, name, tmpl] = part
      parsed = Parse(tmpl)
      data = find(name, context)
      return switch data.constructor
        when Array
          (Generate(parsed, datum, [context...]) for datum in data).join('')
        when Function
          'f(x)'
        else
          if data then Generate(parsed, data, [context...]) else ''
    when '^'
      [_, name, tmpl] = part
      parsed = Parse(tmpl)
      data = find(name, context)
      return switch data.constructor
        when Array
          if data.length == 0 then Generate(parsed, data, [context...]) else ''
        else
          if data then '' else Generate(parsed, data, [context...])
    when '&', '{' then find(part[1], context).toString()
    when '' then escape(find(part[1], context).toString())
    else throw "Unknown tag type: #{part[0]}"

# Partials are generally static; we can store a single reference for now.
Partials = {}

Milk =
  render: (template, data, partials = {}, context = []) ->
    [tagOpen, tagClose] = ['{{', '}}']
    Partials = partials
    parsed = Parse template
    return Generate(parsed, data)

  clearCache: (tmpl...) ->
    TemplateCache = {} unless tmpl.length
    delete TemplateCache[t] for t in tmpl
    return

if exports?
  exports[key] = Milk[key] for key of Milk
else
  this.Milk = Milk
