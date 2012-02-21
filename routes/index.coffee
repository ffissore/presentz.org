fs = require "fs"
path = require "path"
_ = require "underscore"
_s = require "underscore.string"
http = require "http"
url = require "url"
dateutil = require "dateutil"

class NotFound extends Error
  constructor: (msg) ->
    @name = 'NotFound'
    Error.call(this, msg)
    Error.captureStackTrace(this, arguments.callee)
    
render_catalog = (presentations, res) ->
  presentations = _.sortBy presentations, (pres) -> 
    pres.id
  presentations = presentations.reverse()
  res.render "catalog", 
    title: "Catalog",
    presentations: presentations
    
fill_presentation_data_from_file= (catalog_path, file, files, presentations, pres, res) ->
  fs.readFile "#{catalog_path}/#{file}", "utf-8", (err, data) ->
    pres.data = JSON.parse(data)
    pres.thumb = pres.data.chapters[0].media.video.thumb
    pres.title1 = "#{dateutil.format(dateutil.parse(pres.data.time, "YYYYMMDD"), "Y/m")} - #{pres.data.speaker}"
    pres.title2 = pres.data.title
    presentations.push pres
    render_catalog presentations, res if files.length == presentations.length

collect_presentations = (err, files, catalog_path, res) ->
  files = (file for file in files when _s.endsWith file, ".js" or _s.endsWith file, ".json")
  presentations = []
  for file in files
    pres = 
      id: file.substr(0, file.indexOf("."))
    fill_presentation_data_from_file catalog_path, file, files, presentations, pres, res
  return
  
exports.index= (req, res) ->
  res.render "index", 
    title: "Presentz"
    host: req.headers.host
  
exports.show_catalog= (req, res, next) ->
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  path.exists catalog_path, (exists) ->
    return next new NotFound(catalog_path) if not exists
    fs.readdir catalog_path, (err, files) -> 
      collect_presentations err, files, catalog_path, res

exports.show_presentation= (req, res, next) ->
  res.send req.url
