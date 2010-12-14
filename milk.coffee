trim = (str) -> str.replace(/^\s*|\s*$/g, '')

TemplateCache = {}
Partials = {}

tagOpen = '{{'
tagClose = '}}'

# Parses the given template between the start and end indexes.
Parse = (template, sectionName, pos = 0) ->
  # If we've got a cached parse tree for this template, return it.
  return TemplateCache[template] if template of TemplateCache

  # Set up fresh, clean parse and whitespace buffers.
  buffer = []
  whitespace = ''

  # Build a RegExp to match the start of a new tag.
  open  = ///((?:(^|\n)([#{' '}\t]*))?#{tagOpen})///g
  close = ///(#{tagClose})///g
  open.lastIndex = pos

  # Start walking through the template, searching for newly opened tags.
  while open.test(template)
    # Append any text content before the tag, save any intervening whitespace,
    # and advance into the tag itself.  We'll also save off information about
    # whether this tag is potentially "standalone", which would change the
    # processing semantics.
    firstContentOnLine = yes
    if RegExp.leftContext[pos..].length > 0
      buffer.push(RegExp.leftContext[pos..])
      firstContentOnLine = RegExp.$2 == "\n"
    buffer.push(RegExp.$2) if RegExp.$2
    whitespace = RegExp.$3
    pos = open.lastIndex

    # Build the pattern for finding the end of the tag.  Set Delimiter tags and
    # Triple Mustache tags also have mirrored characters, which need to be
    # accounted for and removed.
    offset   = 0
    offset   = 1 if template[pos] in ['=', '{']
    endOfTag = switch template[pos]
      when '=' then ///([=]#{tagClose})///g
      when '{' then ///([}]#{tagClose})///g
      else close
    endOfTag.lastIndex = pos

    # Grab the tag contents, and advance the pointer beyond the end of the tag.
    throw "No end for tag!" unless endOfTag.test(template)
    tag = RegExp.leftContext[pos...]
    pos = endOfTag.lastIndex

    # If the next character in the template is a newline, that implies that
    # this tag was the only content on this line.  Excepting the interpolating
    # tags, this means that the tag in question should disappear from the
    # rendered output completely.  If the tag was not "standalone", or it was
    # an interpolation tag, the whitespace we earlier removed should be re-
    # added.
    if (firstContentOnLine && template[pos] == "\n" && /[^\w{&]/.test(tag[0]))
      pos++
    else
      buffer.push(whitespace) if whitespace

    switch tag[0]
      # Comment Tag
      when '!' then null

      # Partial Tag
      when '>'
        buffer.push [ 'partial', whitespace, Parse(Partials[trim(tag[1..])])]

      # Section Tag
      when '#'
        [section..., pos] = Parse(template, trim(tag[1..]), pos)
        buffer.push [ 'section', trim(tag[1..]), section  ]

      # End Section Tag
      when '/'
        buffer.push(pos)
        return buffer

      # Set Delimiters Tag
      when '='
        [tagOpen, tagClose] = trim(tag[1..]).split(/\s+/)
        open  = ///(((\n)[#{' '}\t]*)?#{tagOpen})///g
        close = ///(#{tagClose})///g

      # Unescaped Interpolation Tag
      when '&', '{'
        buffer.push [ 'unescaped', trim(tag[1..]) ]

      # Escaped Interpolation Tag
      else
        buffer.push [ 'escaped', trim(tag) ]

    # Advance the lastIndex for the open RegExp.
    open.lastIndex = pos

  # Append any remaining template to the buffer.
  buffer.push(template[pos..]) if template[pos..]

  # Cache the buffer for future calls.
  TemplateCache[template] = buffer

  return buffer

escape = (value) ->
  return value.replace(/&/, '&amp;').
               replace(/"/, '&quot;').
               replace(/</, '&lt;').
               replace(/>/, '&gt;')

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
    when 'partial'
      [_, indent, partial] = part
      content = (handle p, context for p in partial).join('')
      content = content.replace(/^(?=.)/gm, indent) if indent
      return content
    when 'section'
      [_, name, parsed] = part
      data = find(name, context)
      return switch data.constructor
        when Array
          (Generate(parsed, datum, [context...]) for datum in data).join('')
        when Function
          'f(x)'
        else
          if data then Generate(parsed, data, [context...]) else ''
    when 'unescaped' then find(part[1], context).toString()
    when 'escaped' then escape(find(part[1], context).toString())
    else throw "Unknown tag type: #{part[0]}"

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