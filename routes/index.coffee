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
    
fill_presentation_data_from_file= (file, file_name, files_length, presentations, req, res) ->
  fs.readFile file, "utf-8", (err, data) ->
    data = JSON.parse(data)
    pres =
      id: "#{req.params.catalog_name}/#{file_name.substr(0, file_name.indexOf("."))}"
      data: data
      thumb: data.chapters[0].media.video.thumb
      title1: "#{dateutil.format(dateutil.parse(data.time, "YYYYMMDD"), "Y/m")} - #{data.speaker}"
      title2: data.title
    presentations.push pres
    render_catalog presentations, res if files_length == presentations.length

collect_presentations = (err, files, catalog_path, req, res) ->
  files = (file for file in files when not _s.startsWith(file, "catalog") and _s.endsWith(file, ".json"))
  presentations = []
  for file in files
    fill_presentation_data_from_file "#{catalog_path}/#{file}", file, files.length, presentations, req, res
  return

exports.static = (view_name) ->
  return (req, res) ->
    res.render view_name,
      title: "Presentz"
      host: req.headers.host
  
exports.index= (req, res) ->
  res.render "index", 
    title: "Presentz"
    host: req.headers.host
  
exports.show_catalog= (req, res, next) ->
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  path.exists catalog_path, (exists) ->
    return next new NotFound(catalog_path) if not exists
    fs.readdir catalog_path, (err, files) -> 
      collect_presentations err, files, catalog_path, req, res

exports.show_presentation= (req, res, next) ->
  fs.readFile "#{__dirname}/..#{req.path}.json", "utf-8", (err, data) ->
    return next new NotFound("#{__dirname}/..#{req.path}.json") if err
    pres = JSON.parse(data)
    res.render "presentation",
      title: pres.title_long || pres.title
      url: "#{req.url_original || req.url}.json"
      
exports.raw_presentation= (req, res, next) ->
  fs.readFile "#{__dirname}/..#{req.path}", "utf-8", (err, data) ->
    return next new NotFound("#{__dirname}/..#{req.path}.json") if err
    data = "#{req.query.jsoncallback}(#{data});" if req.query.jsoncallback
    res.send data
