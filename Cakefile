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

task 'spec:node', 'Creates compliance tests for the Mustache spec in Vows', ->
  readSpecs (file, json) ->
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

readSpecs = (callback) ->
  # Convert the YAML files to Javascript.
  # Requires the YAML and JSON Ruby libraries.
  ruby = '''
         ruby -rubygems
         -e 'require "yaml"'
         -e 'require "json"'
         -e 'YAML::add_builtin_type("code") do |_,value|
               value["js"].tap do |x|
                 def x.to_json(_)
                   "function() { return #{self}; }"
                 end
               end
             end'
         -e 'print YAML.load_file(ARGV[0]).to_json()'
         '''.replace(/\n/gm, ' ')

  dir = path.join(__dirname, 'ext', 'spec', 'specs')
  for file in fs.readdirSync(dir)
    do (file) ->
      exec "#{ruby} -- #{path.join(dir, file)}", (err, stdout, stderr) ->
        throw err if err
        callback(file, stdout)

topic = ->
  try Milk.render(test.template, test.data, test.partials || {})
  catch e then "ERROR: " + e
