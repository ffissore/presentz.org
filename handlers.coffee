coffee = require "coffee-script"

exports.coffeeRenderer = (file, path, index, isLast, callback) ->
  if /\.coffee/.test path
    console.log "Compiling #{path}"
    callback coffee.compile(file)
  else
    callback file