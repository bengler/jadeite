#!/usr/bin/env rake
require "bundler/gem_tasks"

task :default => :prepare
task :prepare do
  puts "Running npm install"
  system("npm install")
  system("npm shrinkwrap")
end
