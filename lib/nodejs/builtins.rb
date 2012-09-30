# Quick and dirty implementations of the node.js standard modules as required by Jade
module NodeJS

  NodeJS.register_builtin('fs', {
    readFileSync: lambda { |this, file, encoding|
      File.read(file).force_encoding("utf-8")
    },
    existsSync: lambda { |this, file|
      File.exist?(file)
    },
    realpathSync: lambda { |this, file|
      File.realpath(file)
    },
    statSync: lambda { |this, file|
      {
        isDirectory: proc { File.directory?(file) },
        isFile: proc { File.file?(file) },
        isSocket: proc { File.socket?(file) },
        isBlockDevice: proc { File.blockdev?(file) },
        isCharacterDevice: proc { File.chardev?(file) },
        isFIFO: proc { File.pipe?(file) },
        isSymbolicLink: proc { File.symlink?(file) }
      }
    }
  })
  NodeJS.register_builtin('path', {
    dirname: lambda { |this, file|
      File.dirname(file)
    },
    basename: lambda { |this, *args|
      File.basename(*args)
    },
    join: lambda { |this, *args|
      File.join(*args)
    }
  })
  NodeJS.register_builtin('vm', {
  })
end