(function() {
  var Escape, Find, Generate, Milk, Parse, TemplateCache, key;
  var __slice = Array.prototype.slice;
  TemplateCache = {};
  Parse = function(template, delimiters, sectionName, start) {
    var BuildRegex, buffer, cache, content, contentEnd, delim, delims, error, isStandalone, match, parseError, pos, tag, tagClose, tagOpen, tagPattern, tmpl, type, whitespace, _name, _ref, _ref2, _ref3, _ref4;
    if (delimiters == null) {
      delimiters = ['{{', '}}'];
    }
    if (sectionName == null) {
      sectionName = null;
    }
    if (start == null) {
      start = 0;
    }
    cache = (TemplateCache[_name = delimiters.join(' ')] || (TemplateCache[_name] = {}));
    if (template in cache) {
      return cache[template];
    }
    buffer = [];
    tagOpen = delimiters[0], tagClose = delimiters[1];
    BuildRegex = function() {
      return RegExp("([\\s\\S]*?)([" + ' ' + "\\t]*)(?:" + tagOpen + "\\s*(?:(=)\\s*(.+?)\\s*=|({)\\s*(.+?)\\s*}|(\\W?)\\s*([\\s\\S]+?))\\s*" + tagClose + ")", "gm");
    };
    tagPattern = BuildRegex();
    tagPattern.lastIndex = pos = start;
    parseError = function(errorPos, message) {
      var carets, endOfLine, indent, lastLine, lastTag, parsedLines;
      (endOfLine = /$/gm).lastIndex = errorPos;
      endOfLine.exec(template);
      parsedLines = template.substr(0, errorPos).split('\n');
      lastLine = parsedLines[parsedLines.length - 1];
      lastTag = template.substr(contentEnd + 1, errorPos - contentEnd - 1);
      indent = new Array(lastLine.length - lastTag.length + 1).join(' ');
      carets = new Array(lastTag.length + 1).join('^');
      return message = [message, '', "Line " + parsedLines.length + ":", lastLine + template.substr(errorPos, endOfLine.lastIndex - errorPos), "" + indent + carets].join("\n");
    };
    while (match = tagPattern.exec(template)) {
      _ref = match.slice(1, 3), content = _ref[0], whitespace = _ref[1];
      type = match[3] || match[5] || match[7];
      tag = match[4] || match[6] || match[8];
      contentEnd = (pos + content.length) - 1;
      pos = tagPattern.lastIndex;
      isStandalone = (contentEnd === -1 || template.charAt(contentEnd) === '\n') && ((_ref2 = template.charAt(pos)) === void 0 || _ref2 === '\n');
      buffer.push(content);
      if (isStandalone && (type !== '' && type !== '&' && type !== '{')) {
        pos += 1;
      } else if (whitespace) {
        buffer.push(whitespace);
        contentEnd += whitespace.length;
        whitespace = '';
      }
      switch (type) {
        case '!':
          break;
        case '':
        case '&':
        case '{':
          buffer.push([type, tag]);
          break;
        case '>':
          buffer.push([type, tag, whitespace]);
          break;
        case '#':
        case '^':
          _ref3 = Parse(template, [tagOpen, tagClose], tag, pos), tmpl = _ref3[0], pos = _ref3[1];
          buffer.push([type, tag, [[tagOpen, tagClose], tmpl]]);
          break;
        case '/':
          if (tag !== sectionName) {
            error = "End Section tag closes '" + tag + "'; expected '" + sectionName + "'!";
          }
          if (sectionName == null) {
            error = "End Section tag '" + tag + "' found, but not in section!";
          }
          if (error) {
            throw parseError(tagPattern.lastIndex, error);
          }
          template = template.slice(start, (contentEnd + 1) || 9e9);
          TemplateCache[delimiters.join(' ')][template] = buffer;
          return [template, pos];
        case '=':
          delims = tag.split(/\s+/);
          if (delims.length !== 2) {
            error = "Set Delimiters tags should have two and only two values!";
          }
          if (error) {
            throw parseError(tagPattern.lastIndex, error);
          }
          _ref4 = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = delims.length; _i < _len; _i++) {
              delim = delims[_i];
              _results.push(delim.replace(/[-[\]{}()*+?.,\\^$|#]/g, "\\$&"));
            }
            return _results;
          })(), tagOpen = _ref4[0], tagClose = _ref4[1];
          tagPattern = BuildRegex();
          break;
        default:
          throw parseError(tagPattern.lastIndex, "Unknown tag type -- " + type);
      }
      tagPattern.lastIndex = pos;
    }
    buffer.push(template.slice(pos));
    return TemplateCache[delimiters.join(' ')][template] = buffer;
  };
  Generate = function(buffer, data, partials, context) {
    var Build, delims, empty, name, part, partial, parts, tmpl, type, v, value;
    if (partials == null) {
      partials = {};
    }
    if (context == null) {
      context = [];
    }
    if (data && data.constructor === Object) {
      context.push(data);
    }
    Build = function(tmpl, data, delims) {
      return Generate(Parse(tmpl, delims), data, partials, __slice.call(context));
    };
    parts = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = buffer.length; _i < _len; _i++) {
        part = buffer[_i];
        _results.push((function() {
          switch (typeof part) {
            case 'string':
              return part;
            default:
              type = part[0], name = part[1], data = part[2];
              if (type !== '>') {
                value = Find(name, context);
              }
              switch (type) {
                case '>':
                  if (!(name in partials)) {
                    throw "Unknown partial '" + name + "'!";
                  }
                  partial = partials[name].toString();
                  if (data) {
                    partial = partial.replace(/^(?=.)/gm, data);
                  }
                  return Build(partial);
                case '#':
                  delims = data[0], tmpl = data[1];
                  switch ((value || (value = [])).constructor) {
                    case Array:
                      return ((function() {
                        var _i, _len, _results;
                        _results = [];
                        for (_i = 0, _len = value.length; _i < _len; _i++) {
                          v = value[_i];
                          _results.push(Build(tmpl, v, delims));
                        }
                        return _results;
                      })()).join('');
                    case Function:
                      return Build(value(tmpl), null, delims);
                    default:
                      return Build(tmpl, value, delims);
                  }
                case '^':
                  delims = data[0], tmpl = data[1];
                  empty = (value || (value = [])) instanceof Array && value.length === 0;
                  if (empty) {
                    return Build(tmpl, null, delims);
                  } else {
                    return '';
                  }
                case '&':
                case '{':
                  if (value instanceof Function) {
                    value = Build(value());
                  }
                  return value.toString();
                case '':
                  if (value instanceof Function) {
                    value = Build(value());
                  }
                  return Escape(value.toString());
                default:
                  throw "Unknown tag type -- " + type;
              }
          }
        })());
      }
      return _results;
    })();
    return parts.join('');
  };
  Find = function(name, stack) {
    var ctx, func, i, value, _ref, _ref2;
    value = '';
    for (i = _ref = stack.length - 1, _ref2 = -1; (_ref <= _ref2 ? i < _ref2 : i > _ref2); (_ref <= _ref2 ? i += 1 : i -= 1)) {
      if (!(name in (ctx = stack[i]))) {
        continue;
      }
      value = ctx[name];
      break;
    }
    if (value instanceof Function) {
      value = value.apply(ctx);
    }
    if ((func = value) instanceof Function) {
      value = function() {
        var result;
        result = func.apply(this, arguments).toString();
        if (arguments.length === 0) {
          ctx[name] = result;
        }
        return result;
      };
    }
    return value != null ? value : '';
  };
  Escape = function(value) {
    var entities;
    entities = {
      '&': 'amp',
      '"': 'quot',
      '<': 'lt',
      '>': 'gt'
    };
    return value.replace(/[&"<>]/g, function(char) {
      return "&" + entities[char] + ";";
    });
  };
  Milk = {
    render: function(template, data, partials) {
      if (partials == null) {
        partials = {};
      }
      return Generate(Parse(template), data, partials);
    }
  };
  if (typeof exports != "undefined" && exports !== null) {
    for (key in Milk) {
      exports[key] = Milk[key];
    }
  } else {
    this.Milk = Milk;
  }
}).call(this);
