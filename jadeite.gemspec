# -*- encoding: utf-8 -*-
require File.expand_path('../lib/jadeite/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors           = ["Bjørge Næss"]
  gem.email             = ["bjoerge@bengler.no"]
  gem.description       = %q{Compile and render Jade templates from Ruby}
  gem.summary           = %q{Jadeite lets you compile and render Jade templates from your Ruby code. Under the hood it uses the Jade node module running in therubyracer's embedded V8 JavaScript engine.}
  gem.homepage          = ""
  
  gem.files             = `git ls-files`.split($\)
  gem.executables       = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files        = gem.files.grep(%r{^(test|spec|features)/})
  gem.name              = "jadeite"
  gem.rubyforge_project = "jadeite"  
  gem.require_paths     = ["lib"]
  gem.version           = Jadeite::VERSION

  gem.extensions = "Rakefile"

  gem.add_dependency "therubyracer"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "simplecov"
end
