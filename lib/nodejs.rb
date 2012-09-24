module NodeJS
  @builtins = {}
  def self.register_builtin(sym, klass)
    @builtins[sym.to_s] = klass
  end
  def self.builtins
    @builtins
  end
  require "nodejs/environment"
  require "nodejs/module"
  require "nodejs/builtins"
end