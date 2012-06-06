# Quick and dirty implementations of the node.js standard modules as required by Jade
module NodeJS

  NodeJS.register_builtin('fs', {
    :readFileSync => lambda {|this, file, encoding|
      File.read(file).force_encoding("utf-8")
    }
  })

  NodeJS.register_builtin('path', {
    :dirname => lambda { |this, file|
      File.dirname(file)
    },
    :basename => lambda { |this, *args|
      File.basename(*args)
    },
    :join => lambda { |this, *args|
      File.join(*args)
    }
    })
end