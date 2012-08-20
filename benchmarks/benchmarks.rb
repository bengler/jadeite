require 'benchmark'
require 'tilt'
require '../lib/jadeite'

TEMPLATES = {
  :form => {
    :user => {}
  },
  :"include-mixin"=> {

  },
  :includes=> {

  }
}
def measure(times, title, &blk)
  puts
  puts "=== #{title} - #{times} times each"
  TEMPLATES.each do |name, data|
    file = "./templates/#{name}.jade"
    puts "=> #{name} (#{file})"
    blk.call(times, file, data)
    puts
  end
end

measure 10000, "Render precompiled templates" do |times, file, data|
  puts Benchmark.measure {
    env = Jadeite::Environment.new
    compiled = env.compile_file(file)
    times.times do
      compiled.render data
    end
  }
end

measure 10000, "Compile and render" do |times, file, data|
  puts Benchmark.measure {
    env = Jadeite::Environment.new
    times.times do
      compiled = env.compile_file(file)
      compiled.render data
    end
  }
end

measure 10, "Initialize environment, compile and render" do |times, file, data|
  puts Benchmark.measure {
    times.times do
      env = Jadeite::Environment.new

      compiled = env.compile_file(file)
      compiled.render data
    end
  }
end
