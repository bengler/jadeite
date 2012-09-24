require 'v8'
require "nodejs"
require "fileutils"
require "digest"

module Jadeite
  class Environment

    DEFAULT_OPTIONS = {
      cache: true,
      cache_dir: ".jadeite-cache",
      compile_options: {
        client: false,
        compileDebug: true
      }
    }.freeze

    def initialize(options={})
      @options = DEFAULT_OPTIONS.merge(options)

      FileUtils.mkdir_p(cache_dir) if cache? and !File.directory?(cache_dir)

      # Setup V8 context
      @context = V8::Context.new

      # Load jade-runtime
      node_env = NodeJS::Environment.new(@context, File.expand_path('../../', __FILE__))
      @context['jade'] = node_env.require('jade-runtime').runtime
      @jade = node_env.require('jade')
    end

    def compile(template_str, opts={})
      opts = compile_options.merge(opts)
      compiled = if cache?
        cached = cached_read(template_str, opts) do
          @jade.compile(template_str, opts.merge(client: true))
        end
        @context.eval(cached)
      else
        @jade.compile(template_str.strip, compile_options.merge(opts))
      end
      Template.new(compiled)
    end

    def render(template_str, data={}, opts={})
      compile(template_str, compile_options.merge(opts)).render(data)
    end

    def compile_file(file, opts = {})
      compile(File.read(file), opts.merge(filename: File.expand_path(file)))
    end

    def render_file(file, data={}, opts = {})
      compile_file(file, opts).render(data)
    end

    def compile_options
      @options[:compile_options]
    end

    def cache?
      !!@options[:cache]
    end

    def cache_dir
      @options[:cache_dir]
    end

    private

    def cached_read(template_str, opts, &blk)
      cache_file = File.join(cache_dir, "#{Digest::MD5.hexdigest("#{template_str}#{opts.inspect}")}.jade.js")
      if File.exists?(cache_file)
        File.read(cache_file)
      else
        File.open(cache_file, "w") do |f|
          cached = "(#{blk.call});"
          f.write(cached)
          cached
        end
      end
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