fs           = require 'fs'
path         = require 'path'
{exec}       = require 'child_process'

option '-o', '--output [DIR]', 'directory for compiled code'

task 'benchmark', 'Run a simple benchmark of Milk', ->
  sys  = require 'sys'
  Milk = require 'milk'
  tmpl = """
         <h1>{{header}}</h1>
         {{#list.length}}
           <ul>
           {{#list}}
             {{#current}}
               <li><strong>{{name}}</strong></li>
             {{/current}}
             {{^current}}
               <li>a href="{{url}}">{{name}}</a></li>
             {{/current}}
           {{/list}}
           </ul>
         {{/list.length}}
         {{^list.length}}
           <p>The list is empty.</p>
         {{/list.length}}
         """

  start = new Date()
  process.addListener 'exit', ->
    sys.error "Time taken: #{ (new Date() - start) / 1000 } secs"

  for i in [0..1000000]
    Milk.render tmpl,
      header: "Colors"
      list: [
        { name: "red",   url: "#Red",   current: yes }
        { name: "green", url: "#Green", current: no  }
        { name: "blue",  url: "#Blue",  current: no  }
      ]

task 'build', 'Rebuilds all public web resources', ->
  invoke('build:js')
  invoke('build:docs')
  invoke('spec:html')

task 'build:js', 'Builds Milk into ./pages (or --output)', (opts) ->
  CoffeeScript = require 'coffee-script'

  out = opts.output or 'pages'
  out = path.join(__dirname, out) unless out[0] = '/'

  fs.readFile path.join(__dirname, 'milk.coffee'), 'utf8', (err, data) ->
    throw err if err
    fs.writeFile path.join(out, 'milk.js'), CoffeeScript.compile(data)

task 'build:docs', 'Builds documentation with Docco', ->
  chain = (commands...) ->
    exec commands.shift(), (err) ->
      throw err if err
      chain commands... if commands.length
  chain 'docco milk.coffee',
        'mv docs/milk.html pages/index.html',
        'rm -r docs',

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
             (function(test) {
               var context = { "topic": #{topic} };
               context[test.desc] = function(r) { equal(r, test.expected) };

               batch[test.name] = context;
             })(tests[i]);
           }

           suite.addBatch(batch);
           suite.export(module);
           """
    testFile = file.replace(/^~/, '').replace(/\.yml$/, '_spec.js')
    fs.writeFile path.join(__dirname, 'test', testFile), test

task 'spec:html', 'Creates compliance tests for the Mustache spec in HTML', ->
  invoke('build:js')
  spec = (file, json) ->
    """
    describe("Mustache Specification - #{file}", function() {
      var tests = #{json}['tests'];
      for (var i = 0; i < tests.length; i++) {
        it(tests[i].desc, buildTest(tests[i]));
      }
    });
    """

  readSpecs spec, (specs) ->
    lib = 'https://github.com/pivotal/jasmine/raw/1.0.1-release/lib'
    fs.writeFile path.join(__dirname, 'pages', 'compliance.html'),
      """
      <html>
      <head>
      <link rel="stylesheet" type="text/css" href="#{lib}/jasmine.css" />
      <script type="text/javascript" src="#{lib}/jasmine.js"></script>
      <script type="text/javascript" src="#{lib}/jasmine-html.js"></script>
      <script type="text/javascript" src="milk.js"></script>
      </head>
      <body>
      <script type="text/javascript">
      function buildTest(test) {
        return function() { expect((#{topic})()).toEqual(test.expected) };
      }
      #{specs.sort().join('\n')}
      jasmine.getEnv().addReporter(new jasmine.TrivialReporter());
      jasmine.getEnv().execute();
      </script>
      </body>
      </html>
      """

readSpecs = (callback, allDone = (->)) ->
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

  results = []
  dir = path.join(__dirname, 'ext', 'spec', 'specs')
  for file in (files = fs.readdirSync(dir))
    continue unless file.match(/\.yml$/)
    do (file) ->
      exec "#{ruby} -- #{path.join(dir, file)}", (err, stdout, stderr) ->
        throw err if err
        results.push(callback(file, stdout))
        allDone(results) if (files.length == results.length)

topic = ->
  try Milk.render(test.template, test.data, test.partials || {})
  catch e then "ERROR: " + e
