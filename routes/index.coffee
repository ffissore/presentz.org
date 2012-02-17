fs = require "fs"
path = require "path"
_ = require "underscore"
_s = require "underscore.string"
http = require "http"
url = require "url"

class NotFound extends Error
  constructor: (msg) ->
    @name = 'NotFound'
    Error.call(this, msg)
    Error.captureStackTrace(this, arguments.callee)
    
render_catalog = (presentations, res) ->
  presentations = _.sortBy presentations, (pres) -> 
    pres.file
  presentations = presentations.reverse()
  res.render "catalog", 
    title: "Catalog",
    presentations: presentations
    
read_json_response = (urlStr, callback) ->
  json = ""
  http.get url.parse(urlStr), (res) ->
    res.on "data", (chunk) ->
      json += chunk
    res.on "end", ->
      callback json, urlStr
      
fill_presentation_data_from_file= (catalog_path, file, files, presentations, pres, res) ->
  fs.readFile "#{catalog_path}/#{file}", "utf-8", (err, data) ->
    pres.data = JSON.parse(data)
    read_json_response "http://vimeo.com/api/v2/video/#{pres.data.chapters[0].media.video.url.match(/\d+/)}.json", (json) ->
      vimeo_data = JSON.parse(json)
      pres.thumb = vimeo_data[0].thumbnail_medium
      presentations.push pres
      render_catalog presentations, res if files.length == presentations.length

collect_presentations = (err, files, catalog_path, res) ->
  files = (file for file in files when _s.endsWith file, ".js" or _s.endsWith file, ".json")
  presentations = []
  for file in files
    pres = 
      file: file
    fill_presentation_data_from_file catalog_path, file, files, presentations, pres, res
  return
  
exports.index= (req, res) ->
  res.render "index", 
    title: "Presentz"
  
exports.show_catalog= (req, res, next) ->
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  path.exists catalog_path, (exists) ->
    return next new NotFound(catalog_path) if not exists
    fs.readdir catalog_path, (err, files) -> 
      collect_presentations err, files, catalog_path, res

