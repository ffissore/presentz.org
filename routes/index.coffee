fs = require "fs"
path = require "path"
###
GET home page.
###

class NotFound extends Error
  constructor: (msg) ->
    @name = 'NotFound'
    Error.call(this, msg)
    Error.captureStackTrace(this, arguments.callee)

exports.index= (req, res) ->
  res.render "index", 
    title: "Presentz"
  
exports.show_catalog= (req, res, next) ->
  catalog_path = "#{__dirname}/../#{req.params.catalog}"
  path.exists catalog_path, (exists) =>
    return next new NotFound(catalog_path) if not exists
    fs.readdir catalog_path, (err, files) ->
      res.send files
