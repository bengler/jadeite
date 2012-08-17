require 'mkmf'
create_makefile("Test")
puts "Running npm install"
system("npm install")
system("npm shrinkwrap")