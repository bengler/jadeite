require 'benchmark'
require '../lib/jadeite'
require '../lib/jadeite/environment'

TEMPLATES = {
  :form => {
    :user => {}
  },
  :"include-mixin" => {

  },
  :includes => {

  }
}
OPTIONS = [
  {
    cache: true
  },
  {
    cache: false
  }
]

def measure(times, title, &blk)
  puts
  puts "=== #{title} - #{times} times each"
  OPTIONS.each do |opts|
    puts "--- Options: #{opts}"
    TEMPLATES.each do |name, data|
      file = "./templates/#{name}.jade"
      puts "=> #{name} (#{file})"
      blk.call(times, file, data, opts)
      puts
    end
  end
end

measure 10000, "Render precompiled templates" do |times, file, data, options|
  puts Benchmark.measure {
    env = Jadeite::Environment.new(options)
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
