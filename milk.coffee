trim = (str) -> str.replace(/^\s*|\s*$/g, '')

TemplateCache = {}

tagOpen = '{{'
tagClose = '}}'

# Parses the given template between the start and end indexes.
Parse = (template, start = 0, end = template.length) ->
  # If we've got a cached parse tree for this template, return it.
  subtemplate = template[start..end]
  return TemplateCache[subtemplate] if template of TemplateCache

  # Set up fresh, clean parse and whitespace buffers.
  buffer = []
  whitespace = ''

  # Build a RegExp to match the start of a new tag.
  open  = ///(?=[ \t]*#{tagOpen})///g
  blank = ///(?=#{tagOpen})///g
  close = ///(?=#{tagClose})///g
  open.lastIndex = start

  # Start walking through the template, searching for opening tags between
  # start and end.
  while open.test(template)
    break if open.lastIndex >= end
    blank.lastIndex = open.lastIndex

    # Append any text content before the tag, save any intervening whitespace,
    # and advance into the tag itself.  We'll also save off information about
    # whether this tag is potentially "standalone", which would change the
    # processing semantics.
    firstContentOnLine = yes
    if open.lastIndex > 0
      buffer.push(template[start...open.lastIndex])
      previousChar = template[start - 1] == "\n"
    blank.test(template)
    whitespace = template[open.lastIndex...blank.lastIndex]
    start = blank.lastIndex + tagOpen.length

    # Build the pattern for finding the end of the tag.  Set Delimiter tags and
    # Triple Mustache tags also have mirrored characters, which need to be
    # accounted for and removed.
    offset   = 0
    offset   = 1 if template[start] in ['=', '{']
    endOfTag = switch template[start]
      when '=' then ///(?=[=]#{tagClose})///g
      when '{' then ///(?=[}]#{tagClose})///g
      else close
    endOfTag.lastIndex = start

    # Grab the tag contents, and advance the pointer beyond the end of the tag.
    throw "No end for tag!" unless endOfTag.test(template)
    tag   = trim(template[start...endOfTag.lastIndex]).split(/\s+|\b/g)
    start = endOfTag.lastIndex + offset + tagClose.length

    # If the next character in the template is a newline, that implies that
    # this tag was the only content on this line.  Excepting the interpolating
    # tags, this means that the tag in question should disappear from the
    # rendered output completely.  If the tag was not "standalone", or it was
    # an interpolation tag, the whitespace we earlier removed should be re-
    # added.
    if (firstContentOnLine and template[start + 1] and tag.length == 1)
      start++
    else
      buffer.push(whitespace)

    # Handle the tag itself.
    tag = switch tag[0]
      when '&', '{'
        throw "Wrong number of parts in tag!" unless tag.length == 2
        [ 'unescaped', tag[1] ]
      else
        throw "Wrong number of parts in tag!" unless tag.length == 1
        [ 'escaped', tag[0] ]
    buffer.push(tag)

    # Advance the lastIndex for the open RegExp.
    open.lastIndex = start

  # Append any remaining template to the buffer.
  buffer.push(template[start..end]) if start < end

  # Cache the buffer for future calls.
  TemplateCache[subtemplate] = buffer

  return buffer

escape = (value) ->
  return value.replace(/&/, '&amp;').
               replace(/"/, '&quot;').
               replace(/</, '&lt;').
               replace(/>/, '&gt;')

find = (name, stack) ->
  for i in [(0)...-1]
    ctx = stack[i]
    continue unless name of ctx
    value = ctx[name]
    return value ? ''
  return ''

handle = (part, context) ->
  return part if typeof part is 'string'
  switch part[0]
    when 'unescaped' then find(part[1], context)
    when 'escaped' then escape(find(part[1], context))
    else throw "Unknown tag type: #{part[0]}"

Milk =
  render: (template, data, context = []) ->
    parsed = Parse template
    context.push data if data
    return (handle(part, context) for part in parsed).join('')

  clearCache: (tmpl...) ->
    TemplateCache = {} unless tmpl.length
    delete TemplateCache[t] for t in tmpl
    return

(exports ? this).Milk = Milk
