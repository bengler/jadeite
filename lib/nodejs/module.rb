module NodeJS
  class Module
    attr_accessor :exports
    def initialize(environmnent, file)
      @environment = environmnent
      @file = file
      @exports = @environment.new_object
    end

    # Used to require both script files and modules
    # Script path is relative from base path and defines where the require function will begin looking for 
    # require()'d js-files
    # script_path is ignored when requiring modules, i.e. require("jade")
    def require_function
      lambda do |*args|
        this, module_id = *args

        module_id ||= this #backwards compatibility with TRR < 0.10

        return @environment.require(module_id) if NodeJS.builtins.keys.include?(module_id)

        #puts "requiring #{module_id} from #{CommonJS.resolve(@file.dirname, module_id).to_s}"
        @environment.require(NodeJS.resolve(@file.dirname, module_id).to_s)
      end
    end

  end
end