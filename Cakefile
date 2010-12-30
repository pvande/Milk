fs           = require 'fs'
path         = require 'path'
{exec}       = require 'child_process'
CoffeeScript = require 'coffee-script'

option '-o', '--output [DIR]', 'directory for compiled code'

task 'build:js', 'Builds Milk into ./pages (or --output)', (options) ->
  out  = options.output or 'pages'
  out  = path.join(__dirname, out) unless out[0] = '/'

  fs.readFile path.join(__dirname, 'milk.coffee'), 'utf8', (err, data) ->
    throw err if err
    fs.writeFile path.join(out, 'milk.js'), CoffeeScript.compile(data)

task 'spec:node', 'Creates compliance tests for the Mustache spec', ->
  # Convert the YAML files to Javascript.
  # Requires the YAML and JSON libraries.
  ruby =  'ruby -rubygems -e "require \'yaml\'" -e "require \'json\'"'
  ruby += " -e 'YAML::add_builtin_type(\"code\") do"
  ruby += "   |_,v| v[\"js\"].tap do |x|"
  ruby += "     def x.to_json(_)"
  ruby += "       \"function() { return \#{self}; }\""
  ruby += "     end"
  ruby += "   end"
  ruby += " end'"
  ruby += " -e 'print YAML.load_file(ARGV[0]).to_json()'"

  dir   = path.join(__dirname, 'ext', 'spec', 'specs')
  files = fs.readdirSync dir
  for file in files
    do (file) ->
      exec "#{ruby} -- #{path.join(dir, file)}", (err, json, _) ->
        throw err if err

        test = """
               vows  = require('vows');
               equal = require('assert').equal;
               Milk  = require('milk');
               suite = vows.describe('Mustache Specification - #{file}');

               tests  = #{json}['tests'];

               var batch = {};
               for (var i = 0; i < tests.length; i++) {
                 var test = tests[i];

                 var context = {};
                 context['topic']   = #{topic};
                 context[test.desc] = function(r) { equal(r, test.expected) };

                 batch[test.name] = context
               }

               suite.addBatch(batch);
               suite.export(module);
               """
        testFile = file.replace(/^~/, '').replace(/\.yml$/, '_spec.js')
        fs.writeFile path.join(__dirname, 'test', testFile), test

topic = ->
  try Milk.render(test.template, test.data, test.partials || {})
  catch e then "ERROR: " + e
