require 'v8'
require "nodejs"

module Jadeite
  class Environment
    def initialize
      context = V8::Context.new
      context.eval("var process = {env: {}}")
      context.load(File.expand_path(File.join('../../../', 'node_modules/jade/runtime.js'), __FILE__))

      node_env = NodeJS::Environment.new(context, File.expand_path('../../', __FILE__))
      @jade = node_env.require('jade')
    end

    def compile(template_str, opts={})
      Template.new(@jade.compile(template_str.strip, opts))
    end

    def render(template_str, data={}, opts={})
      compile(template_str, opts).render(data)
    end
  
    def compile_file(file, opts = {})
      opts.merge!(:filename => File.expand_path(file))
      compile(File.read(file), opts)
    end

    def render_file(file, data={}, opts = {})
      compile_file(file, opts).render(data)
    end
  end

  private
  class Template
    def initialize(compiled)
      @compiled = compiled
    end
    def render(data={})
      @compiled.call data
    end
    def to_s
      @compiled.to_s
    end
  end
end