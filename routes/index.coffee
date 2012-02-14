fs = require "fs"
path = require "path"
_s = require "underscore.string"

class NotFound extends Error
  constructor: (msg) ->
    @name = 'NotFound'
    Error.call(this, msg)
    Error.captureStackTrace(this, arguments.callee)

exports.index= (req, res) ->
  res.render "index", 
    title: "Presentz"
  
exports.show_catalog= (req, res, next) ->
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  path.exists catalog_path, (exists) =>
    return next new NotFound(catalog_path) if not exists
    fs.readdir catalog_path, (err, files) ->
      files = (file for file in files when _s.endsWith file, ".js" or _s.endsWith file, ".json")
      presentations = []
      for file in files
        fs.readFile "#{catalog_path}/#{file}", "utf-8", (err, data) ->
          presentations.push
            file: file
            data: JSON.parse(data)
          if files.length == presentations.length
            res.render "catalog", 
              title: "Catalog",
              presentations: presentations

