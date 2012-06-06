A Naïve implementation of Node.js require() in [therubyracer](https://github.com/cowboyd/therubyracer).

Based on [commonjs.rb](https://github.com/cowboyd/commonjs.rb) by Charles Lowell (cowboyd) but has a few notable extra features:

- If a directory is passed to require(), it will look for dirname/index.js
- If a module id is passed to require(), it will look in the node_modules subdirectory for a directory matching the module name,
  read package.json from that directory and require the main entry javascript file.

# Disclaimer

This is by no means a solid implementation of the module loader in NPM. It is written to solve a very
specific task: to be able to require the jade npm module in therubyracer. If it works with other libraries, 
it is most likely out of pure luck.

# Usage:

```ruby

env = NodeJS::Environment.new(V8::Context.new, File.expand_path(__FILE__))

# Will look for ./node_modules/lalala/package.json and require() the specified main entry file
lalala = env.require("lalala")
puts lalala.saySomething("arg1", "arg2")

somejs = env.require("./path/to/some.js")

puts somejs.doSomething(:test => "hello")

```