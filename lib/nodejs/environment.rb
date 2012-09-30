require 'json'
require 'pathname'
module NodeJS
  class Environment
    def initialize(context)
      @context = context
      @context['runInThisContext'] = lambda {|this, code, filename|
        @context.eval(code, filename)
      }
      @context['process'] = {
        env: {},
        cwd: -> { Dir.getwd },
        stdout: {
          write: lambda {|this, *out| $stdout.puts out.join(" ") }
        }
      }
      module_src = File.join(File.dirname(__FILE__), "./module.js")
      @module = @context.eval(File.read(module_src), File.expand_path(module_src))
    end
    def Module
      @module.call(NodeJS.builtins)
    end
  end

end