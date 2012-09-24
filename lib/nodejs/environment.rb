require 'json'
require 'pathname'
module NodeJS
  class Environment
    def initialize(context, base_path)
      @context = context
      @base_path = Pathname(base_path)
      @cache = {}
      @context.eval("var process = {env: {}}")
    end

    def new_object
      @context['Object'].new
    end

    def require(module_or_path)
      # module main or single js file to require

      return NodeJS.builtins[module_or_path] if NodeJS.builtins[module_or_path]
      
      file = NodeJS.resolve(@base_path.dirname, module_or_path)
      return @cache[file].exports if @cache[file]

      mod = @cache[file] = Module.new(self, file)

      loader = @context.eval("(function(module, require, exports) {#{File.read(file)}});", file.to_s)
      loader.call(mod, mod.require_function, mod.exports)
      mod.exports
    end
  end

  def self.resolve(base_path, module_or_path)
    NodeJS.send(module_or_path =~ /^(\.|\/)/ ? :resolve_file : :resolve_module, base_path, module_or_path)
  end

  def self.resolve_file(base_path, path)
    full_path = base_path.join(path)
    return NodeJS.resolve_file(base_path, full_path.join("index.js")) if full_path.directory?
    unless File.exists?(full_path) && full_path.extname =~ /\.js$/
      full_path = Pathname("#{full_path.to_s}.js")
    end
    fail LoadError, "Module '#{full_path}' not found" unless full_path.file?
    full_path
  end

  def self.resolve_module(base_path, module_name)
    module_dir = base_path.join("node_modules", module_name)
    package_json = module_dir.join("package.json")
    fail LoadError, "Module '#{module_name}' not found" unless package_json.file?
    module_def = JSON.parse(File.read(package_json))
    module_dir.join(module_def['main'])
  end
end