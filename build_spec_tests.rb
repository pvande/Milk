# Since Javascript's YAML libraries are still very young, we'll preprocess them
# and build a test suite all at once.
require 'yaml'
require 'json'

__DIR__ = File.dirname(__FILE__)
SPECS = File.join(__DIR__, 'ext', 'spec', 'specs')

YAML::add_builtin_type('code') do |_, val|
  func = val['js']
  def func.to_json(_); " `function() { return #{self} }`"; end
  func
end

Dir["#{SPECS}/*.yml"].each do |file|
  basename = File.basename(file)[/\w+/]
  tests = YAML.load_file(file)
  File.open(File.join(__DIR__, 'test', "#{basename}_spec.coffee"), 'w') do |f|
    basename[0] = basename[0, 1].upcase
    f.puts <<-COFFEE.gsub(/^      /, '')
      vows   = require 'vows'
      assert = require 'assert'

      Milk   = require 'milk'

      suite = vows.describe 'Mustache Specification - #{basename}'
      suite.addBatch
    COFFEE

    tests['tests'].each do |t|
      t.keys.each { |key| t[key] = t[key].to_json }

      f.puts <<-COFFEE.gsub(/^      /, '')
        #{t['name']}:
          topic: ->
            try
              Milk.render #{t['template']}, #{t['data']}, #{t['partials'] || '{}'}
            catch e
              return "ERROR: " + e

          #{t['desc'].inspect}: (result) ->
            assert.equal(result, #{t['expected']})

      COFFEE
    end

    f.puts("suite.export(module)")
  end
end
