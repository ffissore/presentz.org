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
    Error.call this, msg
    Error.captureStackTrace this, arguments.callee
    
render_catalog = (catalog, presentations, req, res) ->
  presentations = _.sortBy presentations, (pres) -> 
    pres.id
  presentations = presentations.reverse()
  res.render "catalog",
    title: "#{catalog.name} is on Presentz",
    catalog: catalog
    presentations: presentations
    
fill_presentation_data_from_file= (file, file_name, files_length, catalog, computed_files, presentations, req, res) ->
  fs.readFile file, "utf-8", (err, data) ->
    computed_files.push file
    
    data = JSON.parse data
    
    return if data.alias_of
    
    pres =
      id: "#{req.params.catalog_name}/#{file_name.substr(0, file_name.indexOf("."))}"
      data: data
      thumb: data.chapters[0].media.video.thumb

    if data.speaker
      pres.title1 = data.speaker
      pres.title1 = "#{dateutil.format(dateutil.parse(data.time, "YYYYMMDD"), "Y/m")} - #{pres.title1}" if data.time
      pres.title2 = data.title
    else
      pres.title1 = data.title
    pres.title = pres.title1
    pres.title += " - #{pres.title2}" if pres.title2

    presentations.push pres
    render_catalog catalog, presentations, req, res if files_length == computed_files.length

collect_presentations = (err, files, catalog_path, req, res, catalog) ->
  files = (file for file in files when not _s.startsWith(file, "catalog") and _s.endsWith(file, ".json"))
  presentations = []
  computed_files = []
  for file in files
    fill_presentation_data_from_file "#{catalog_path}/#{file}", file, files.length, catalog, computed_files, presentations, req, res
  return
  
read_catalog = (catalog_path, req, next, callback) ->
  fs.readFile "#{catalog_path}/catalog.json", "utf-8", (err, data) ->
    return next new NotFound("catalog in #{catalog_path}") if err
    catalog = JSON.parse data
    catalog.id = req.params.catalog_name
    callback(catalog)
    
find_file = (path, filename, callback) ->
  fs.readdir path, (err, files) ->
    throw next new NotFound(path) if err
    filtered_files = _.filter files, (file) ->
      file.indexOf(filename) isnt -1
    if filtered_files.length is 1
      fs.readFile "#{path}/#{filtered_files[0]}", "utf-8", (err, data) ->
        callback filtered_files[0].substring(0, filtered_files[0].indexOf(".")), data
    else
      callback

redirect_to_presentation = (req, res, filename) ->
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  find_file catalog_path, filename, (filename, data) ->
    data = JSON.parse data
    if data.alias_of
      res.redirect "/#{req.params.catalog_name}/#{data.alias_of}", 301
    else
      res.redirect "/#{req.params.catalog_name}/#{filename}", 301
      
exports.catalog_name_by_third_domain = () ->
  third_level_domain_regex = /([\w]+)\.[\w]+\..+/
  return (req, res, next) ->
    unless req.url.indexOf("/assets") is 0 
      proxy = req.headers["x-forwarded-host"]
      if proxy
        match = proxy.match third_level_domain_regex
        if match and req.url.indexOf("/#{match[1]}") isnt 0
          req.url = "/#{match[1]}#{req.url}"
    next()

exports.static = (view_name) ->
  return (req, res) ->
    res.render view_name,
      title: "Presentz"
  
exports.show_catalog= (req, res, next) ->
  console.log "show_catalog"
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  path.exists catalog_path, (exists) ->
    return next new NotFound(catalog_path) if not exists
    read_catalog catalog_path, req, next, (catalog) ->
      fs.readdir catalog_path, (err, files) -> 
        collect_presentations err, files, catalog_path, req, res, catalog

exports.show_presentation= (req, res, next) ->
  console.log "show_presentation"
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  read_catalog catalog_path, req, next, (catalog) ->
    fs.readFile "#{__dirname}/..#{req.path}.json", "utf-8", (err, data) ->
      return next new NotFound("#{__dirname}/..#{req.path}.json") if err
      pres = JSON.parse data
      res.render "presentation",
        title: pres.title_long || pres.title
        catalog: catalog
        url: "#{req.url_original || req.url}.json"
        thumb: pres.chapters[0].media.video.thumb
      
exports.raw_presentation= (req, res, next) ->
  console.log "raw_presentation"
  fs.readFile "#{__dirname}/..#{req.path}", "utf-8", (err, data) ->
    return next new NotFound("#{__dirname}/..#{req.path}.json") if err
    data = "#{req.query.jsoncallback}(#{data});" if req.query.jsoncallback
    res.send data
    
exports.redirect_to_presentation_from_html= (req, res, next) ->
  console.log "redirect_to_presentation_from_html"
  redirect_to_presentation req, res, req.params.presentation
  
exports.redirect_to_presentation_from_p_html= (req, res, next) ->
  console.log "redirect_to_presentation_from_p"
  redirect_to_presentation req, res, req.query.p
