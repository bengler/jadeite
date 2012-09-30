// lame "reinvent-the-wheel"-utility functions
function extend(obj, otherObj) {
  for (var prop in otherObj) if (otherObj.hasOwnProperty(prop)) {
    obj[prop] = otherObj[prop];
  }
}
function clone(obj) {
  var target = {};
  for (var prop in obj) if (obj.hasOwnProperty(prop)) {
    target[prop] = obj[prop];
  }
  return target;
}

function merge(obj, otherObj) {
  var target = clone(obj);
  for (var prop in otherObj) if (otherObj.hasOwnProperty(prop)) {
    target[prop] = otherObj[prop];
  }
  return target;
}
//----

var _helpers = {};

module.exports = function (helpers) {
  extend(_helpers, helpers);
};

module.exports.merge = function (locals) {
  return merge(_helpers, locals);
};