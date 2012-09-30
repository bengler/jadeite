require 'v8'
require "nodejs"
require "fileutils"
require "digest"
require 'singleton'

module Jadeite
  class Environment
    include Singleton

    def self.configure(&blk)
      blk.call(self.instance)
    end

    def initialize
      # Setup V8 context
      @context = V8::Context.new

      @node_env = NodeJS::Environment.new(@context)
      jadeite = @node_env.Module._load(File.expand_path('../../../index.js', __FILE__))
      @jade = jadeite.jade
      @context['jade'] = jadeite.require('jade-runtime').runtime

      @context['JADE_HELPERS'] =  @node_env.Module._load(File.expand_path('../helpers', __FILE__))

      # Create a new object in V8 that will keep a cached copy of compiled templates
      @cache = @context['Object'].new
      yield self if block_given?
    end

    def load(path)
      @node_env.Module._load(path)
    end

    def helpers(helpers)
      @context['JADE_HELPERS'].call(helpers)
    end

    def compile(template_str, opts={})
      compiled = cached_read(template_str, opts) {
        wrapped = <<-js.strip
          (function(locals, attrs, escape, rethrow, merge) {
            locals = JADE_HELPERS.merge(locals);
            return (#{@jade.compile(template_str, opts.merge(client: true))})(locals, attrs, escape, rethrow, merge);
          });
        js
        @context.eval(wrapped)
      }
      Template.new(compiled, @context)
    end

    def render(template_str, data={}, opts={})
      compile(template_str, opts).render(data)
    end

    def compile_file(file, opts = {})
      compile(File.read(file), opts.merge(filename: File.expand_path(file)))
    end

    def render_file(file, data={}, opts = {})
      compile_file(file, opts).render(data)
    end

    private

    def cached_read(template_str, opts, &blk)
      key = Digest::MD5.hexdigest("#{template_str}#{opts.inspect}")
      @cache[key] = blk.call unless @cache[key]
      @cache[key]
    end
  end

  private
  class Template

    def initialize(compiled, context)
      @compiled = compiled
      @context = context
    end

    def render(data={})
      @compiled.call(@context['JSON'].parse(data.to_json))
    end

    def to_s
      @compiled.to_s
    end
  end
end