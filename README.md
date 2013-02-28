```
________       _________    __________      
______(_)_____ ______  /_______(_)_  /_____ 
_____  /_  __ `/  __  /_  _ \_  /_  __/  _ \
____  / / /_/ // /_/ / /  __/  / / /_ /  __/
___  /  \__,_/ \__,_/  \___//_/  \__/ \___/ 
/___/ Compile and render Jade templates from Ruby

```

[![Build Status](https://semaphoreapp.com/api/v1/projects/36a547252959a65eeb492fea1278fb77c3473d4e/28284/badge.png)](https://semaphoreapp.com/projects/1581/branches/28284)

Jadeite lets you compile and render [Jade](http://jade-lang.com) templates from your Ruby code.
Under the hood it uses the Jade node module running in
[therubyracer's](https://github.com/cowboyd/therubyracer) embedded V8 JavaScript engine.

It is pretty cool since it means you can easily share templates between the server side and front end.
Render with json/javascript data on the client side and ruby objects on the server side.

## Getting started

Add this line to your application's Gemfile:

    gem 'jadeite'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jadeite

## Usage

### Render a template string with data

```ruby
env = Jadeite::Environment.new
env.render('p Hello #{what}!', {:what =>"world"})
#=> "<p>Hello world!</p>"
```

### Compile once, render twice (or more)

```ruby
env = Jadeite::Environment.new
compiled = env.compile('p Hello #{what}!')
compiled.render :what => "world"
#=> "<p>Hello world!</p>"
compiled.render :what => "moon"
#=> "<p>Hello moon!</p>"
```

### Compile / render a file

```ruby
env = Jadeite::Environment.new

# compile first
compiled = env.compile_file("./hello.jade")
compiled.render :what => "world"
#=> "<p>Hello world!</p>"

# or simply
env.render_file("./hello.jade", :what => "moon")
#=> "<p>Hello moon!</p>"
```

### Output compiled template function (i.e. for serving your front-end views)

```ruby
env = Jadeite::Environment.new
env.compile 'p Hello #{what}!', :client => true, :compileDebug => false
#=> function anonymous(locals, attrs, escape, rethrow, merge) {
# var attrs = jade.attrs, escape = jade.escape, rethrow = jade.rethrow, merge = jade.merge;
# var buf = [];
# with (locals || {}) {
# var interp;
# buf.push('<p>Hello ' + escape((interp = what) == null ? '' : interp) + '!</p>');
# }
# return buf.join("");
# }

```

See https://github.com/visionmedia/jade#browser-support for more info.

### API
Instances of Jadeite::Environment has two public methods:

`compile(template_string, options)` and `render(template_string, data, options)`
in where the `options` argument for both of them corresponds to the options argument in
[Jade's public api](https://github.com/visionmedia/jade#public-api).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
