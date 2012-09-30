// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.
(function(Builtins) {

  var debug = function() {
    //process.stdout.write.apply(null, arguments);
  };

  var path = (function() {
    var exports = {}
    function filter (xs, fn) {
        var res = [];
        for (var i = 0; i < xs.length; i++) {
            if (fn(xs[i], i, xs)) res.push(xs[i]);
        }
        return res;
    }

    // resolves . and .. elements in a path array with directory names there
    // must be no slashes, empty elements, or device names (c:\) in the array
    // (so also no leading and trailing slashes - it does not distinguish
    // relative and absolute paths)
    function normalizeArray(parts, allowAboveRoot) {
      // if the path tries to go above the root, `up` ends up > 0
      var up = 0;
      for (var i = parts.length; i >= 0; i--) {
        var last = parts[i];
        if (last == '.') {
          parts.splice(i, 1);
        } else if (last === '..') {
          parts.splice(i, 1);
          up++;
        } else if (up) {
          parts.splice(i, 1);
          up--;
        }
      }

      // if the path is allowed to go above the root, restore leading ..s
      if (allowAboveRoot) {
        for (; up--; up) {
          parts.unshift('..');
        }
      }

      return parts;
    }

    // Regex to split a filename into [*, dir, basename, ext]
    // posix version
    var splitPathRe = /^(.+\/(?!$)|\/)?((?:.+?)?(\.[^.]*)?)$/;

    // path.resolve([from ...], to)
    // posix version
    exports.resolve = function() {
    var resolvedPath = '',
        resolvedAbsolute = false;

    for (var i = arguments.length; i >= -1 && !resolvedAbsolute; i--) {
      var path = (i >= 0)
          ? arguments[i]
          : process.cwd();

      // Skip empty and invalid entries
      if (typeof path !== 'string' || !path) {
        continue;
      }

      resolvedPath = path + '/' + resolvedPath;
      resolvedAbsolute = path.charAt(0) === '/';
    }

    // At this point the path should be resolved to a full absolute path, but
    // handle relative paths to be safe (might happen when process.cwd() fails)

    // Normalize the path
    resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
        return !!p;
      }), !resolvedAbsolute).join('/');

      return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
    };

    // path.normalize(path)
    // posix version
    exports.normalize = function(path) {
    var isAbsolute = path.charAt(0) === '/',
        trailingSlash = path.slice(-1) === '/';

    // Normalize the path
    path = normalizeArray(filter(path.split('/'), function(p) {
        return !!p;
      }), !isAbsolute).join('/');

      if (!path && !isAbsolute) {
        path = '.';
      }
      if (path && trailingSlash) {
        path += '/';
      }

      return (isAbsolute ? '/' : '') + path;
    };


    // posix version
    exports.join = function() {
      var paths = Array.prototype.slice.call(arguments, 0);
      return exports.normalize(filter(paths, function(p, index) {
        return p && typeof p === 'string';
      }).join('/'));
    };


    exports.dirname = function(path) {
      var dir = splitPathRe.exec(path)[1] || '';
      var isWindows = false;
      if (!dir) {
        // No dirname
        return '.';
      } else if (dir.length === 1 ||
          (isWindows && dir.length <= 3 && dir.charAt(1) === ':')) {
        // It is just a slash or a drive letter with a slash
        return dir;
      } else {
        // It is a full dirname, strip trailing slash
        return dir.substring(0, dir.length - 1);
      }
    };


    exports.basename = function(path, ext) {
      var f = splitPathRe.exec(path)[2] || '';
      // TODO: make this comparison case-insensitive on windows?
      if (ext && f.substr(-1 * ext.length) === ext) {
        f = f.substr(0, f.length - ext.length);
      }
      return f;
    };


    exports.extname = function(path) {
      return splitPathRe.exec(path)[3] || '';
    };
    return exports
  }());

  var fs = Builtins.fs;

  // If obj.hasOwnProperty has been overridden, then calling
  // obj.hasOwnProperty(prop) will break.
  // See: https://github.com/joyent/node/issues/1707
  function hasOwnProperty(obj, prop) {
    return Object.prototype.hasOwnProperty.call(obj, prop);
  }

  function Module(id, parent, sandbox) {
    this.id = id;
    this.exports = {};
    this.parent = parent;
    this.sandbox = sandbox;
    if (parent && parent.children) {
      parent.children.push(this);
    }

    this.filename = null;
    this.loaded = false;
    this.children = [];
  }

  Module._cache = {};
  Module._pathCache = {};
  Module._extensions = {};
  var modulePaths = [];

  // check if the directory is a package.json dir
  var packageCache = {};

  function readPackage(requestPath) {
    if (hasOwnProperty(packageCache, requestPath)) {
      return packageCache[requestPath];
    }

    try {
      var jsonPath = path.resolve(requestPath, 'package.json');
      var json = fs.readFileSync(jsonPath, 'utf8');
    } catch (e) {
      return false;
    }

    try {
      var pkg = packageCache[requestPath] = JSON.parse(json);
    } catch (e) {
      e.path = jsonPath;
      e.message = 'Error parsing ' + jsonPath + ': ' + e.message;
      throw e;
    }
    return pkg;
  }

  function tryPackage(requestPath, exts) {
    var pkg = readPackage(requestPath);

    if (!pkg || !pkg.main) return false;

    var filename = path.resolve(requestPath, pkg.main);
    return tryFile(filename) || tryExtensions(filename, exts) ||
           tryExtensions(path.resolve(filename, 'index'), exts);
  }

  // In order to minimize unnecessary lstat() calls,
  // this cache is a list of known-real paths.
  // Set to an empty object to reset.
  Module._realpathCache = {};

  // check if the file exists and is not a directory
  function tryFile(requestPath) {
    if (!fs.existsSync(requestPath)) return false;
    var stats = fs.statSync(requestPath);
    if (stats && !stats.isDirectory()) {
      return fs.realpathSync(requestPath, Module._realpathCache);
    }
    return false;
  }

  // given a path check a the file exists with any of the set extensions
  function tryExtensions(p, exts) {
    for (var i = 0, EL = exts.length; i < EL; i++) {
      var filename = tryFile(p + exts[i]);

      if (filename) {
        return filename;
      }
    }
    return false;
  }


  Module._findPath = function(request, paths) {
    var exts = Object.keys(Module._extensions);

    if (request.charAt(0) === '/') {
      paths = [''];
    }

    var trailingSlash = (request.slice(-1) === '/');

    var cacheKey = JSON.stringify({request: request, paths: paths});
    if (Module._pathCache[cacheKey]) {
      return Module._pathCache[cacheKey];
    }

    // For each path
    for (var i = 0, PL = paths.length; i < PL; i++) {
      var basePath = path.resolve(paths[i], request);
      var filename;

      if (!trailingSlash) {
        // try to join the request to the path
        filename = tryFile(basePath);

        if (!filename && !trailingSlash) {
          // try it with each of the extensions
          filename = tryExtensions(basePath, exts);
        }
      }

      if (!filename) {
        filename = tryPackage(basePath, exts);
      }

      if (!filename) {
        // try it with each of the extensions at "index"
        filename = tryExtensions(path.resolve(basePath, 'index'), exts);
      }

      if (filename) {
        Module._pathCache[cacheKey] = filename;
        return filename;
      }
    }
    return false;
  };

  // 'from' is the __dirname of the module.
  Module._nodeModulePaths = function(from) {
    // guarantee that 'from' is absolute.
    from = path.resolve(from);

    // note: this approach *only* works when the path is guaranteed
    // to be absolute.  Doing a fully-edge-case-correct path.split
    // that works on both Windows and Posix is non-trivial.
    var splitRe = /\//;
    // yes, '/' works on both, but let's be a little canonical.
    var joiner = '/';
    var paths = [];
    var parts = from.split(splitRe);

    for (var tip = parts.length - 1; tip >= 0; tip--) {
      // don't search in .../node_modules/node_modules
      if (parts[tip] === 'node_modules') continue;
      var dir = parts.slice(0, tip + 1).concat('node_modules').join(joiner);
      paths.push(dir);
    }

    return paths;
  };

  Module._resolveLookupPaths = function(request, parent) {
    var start = request.substring(0, 2);
    if (start !== './' && start !== '..') {
      var paths = modulePaths;
      if (parent) {
        if (!parent.paths) parent.paths = [];
        paths = parent.paths.concat(paths);
      }
      return [request, paths];
    }

    // with --eval, parent.id is not set and parent.filename is null
    if (!parent || !parent.id || !parent.filename) {
      // make require('./path/to/foo') work - normally the path is taken
      // from realpath(__filename) but with eval there is no filename
      var mainPaths = ['.'].concat(modulePaths);
      mainPaths = Module._nodeModulePaths('.').concat(mainPaths);
      return [request, mainPaths];
    }

    // Is the parent an index module?
    // We can assume the parent has a valid extension,
    // as it already has been accepted as a module.
    var isIndex = /^index\.\w+?$/.test(path.basename(parent.filename));
    var parentIdPath = isIndex ? parent.id : path.dirname(parent.id);
    var id = path.resolve(parentIdPath, request);

    // make sure require('./path') and require('path') get distinct ids, even
    // when called from the toplevel js file
    if (parentIdPath === '.' && id.indexOf('/') === -1) {
      id = './' + id;
    }

    debug('RELATIVE: requested:' + request +
          ' set ID to: ' + id + ' from ' + parent.id);

    return [id, [path.dirname(parent.filename)]];
  };


  Module._load = function(request, parent, isMain, sandbox) {
    if (parent) {
      debug('Module._load REQUEST  ' + (request) + ' parent: ' + parent.id);
    }

    var filename = Module._resolveFilename(request, parent);

    debug("Filename resolved to: "+filename);

    var cachedModule = Module._cache[filename];
    if (cachedModule) {
      return cachedModule.exports;
    }

    var module = new Module(filename, parent, sandbox);

    if (isMain) {
      module.id = '.';
    }

    Module._cache[filename] = module;

    var hadException = true;

    try {
      module.load(filename);
      hadException = false;
    } finally {
      if (hadException) {
        delete Module._cache[filename];
      }
    }

    return module.exports;
  };

  Module._resolveFilename = function(request, parent) {

    var resolvedModule = Module._resolveLookupPaths(request, parent);
    var id = resolvedModule[0];
    var paths = resolvedModule[1];

    // look up the filename first, since that's the cache key.
    debug('looking for ' + JSON.stringify(id) +
          ' in ' + JSON.stringify(paths));

    var filename = Module._findPath(request, paths);
    if (!filename) {
      var err = new Error("Cannot find module '" + request + "'");
      err.code = 'MODULE_NOT_FOUND';
      throw err;
    }
    return filename;
  };


  Module.prototype.load = function(filename) {
    debug('load ' + JSON.stringify(filename) +
          ' for module ' + JSON.stringify(this.id));

    this.filename = filename;
    this.paths = Module._nodeModulePaths(path.dirname(filename));

    var extension = path.extname(filename) || '.js';
    if (!Module._extensions[extension]) extension = '.js';
    Module._extensions[extension](this, filename);
    this.loaded = true;
  };

  Module.prototype.require = function(path) {
    if (Builtins[path]) { return Builtins[path]; }
    return Module._load(path, this, false, this.sandbox);
  };

  // Returns exception if any
  Module.prototype._compile = function(content, filename) {
    "use strict"; // Prevent arguments.callee attacks

    var self = this;
    // remove shebang
    content = content.replace(/^\#\!.*/, '');

    function require(path) {
      return self.require(path);
    }

    require.resolve = function(request) {
      return Module._resolveFilename(request, self);
    };

    // Enable support to add extra extension types
    require.extensions = Module._extensions;

    require.cache = Module._cache;

    var dirname = path.dirname(filename);

    var wrapper = "(function(exports, require, module, __filename, __dirname) {arguments = undefined;"+content+"})";

    var compiledWrapper = runInThisContext(wrapper, self.sandbox, filename, true);
    compiledWrapper.call({}, self.exports, require, self, filename, dirname);
  };

  function stripBOM(content) {
    // Remove byte order marker. This catches EF BB BF (the UTF-8 BOM)
    // because the buffer-to-string conversion in `fs.readFileSync()`
    // translates it to FEFF, the UTF-16 BOM.
    if (content.charCodeAt(0) === 0xFEFF) {
      content = content.slice(1);
    }
    return content;
  }

  // Native extension for .js
  Module._extensions['.js'] = function(module, filename) {
    var content = fs.readFileSync(filename, 'utf8');
    module._compile(stripBOM(content), filename);
  };

  // Native extension for .json
  Module._extensions['.json'] = function(module, filename) {
    var content = fs.readFileSync(filename, 'utf8');
    module.exports = JSON.parse(stripBOM(content));
  };

  return Module;
});