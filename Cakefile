fs           = require 'fs'
path         = require 'path'
CoffeeScript = require 'coffee-script'

option '-o', '--output [DIR]', 'directory for compiled code'

task 'build:js', 'Builds Milk into ./pages (or --output)', (options) ->
  out  = options.output or 'pages'
  out  = path.join(__dirname, out) unless out[0] = '/'

  fs.readFile path.join(__dirname, 'milk.coffee'), 'utf8', (err, data) ->
    throw err if err
    fs.writeFile path.join(out, 'milk.js'), CoffeeScript.compile(data)
