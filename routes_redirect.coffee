fs = require "fs"

find_file = (path, filename, callback) ->
  fs.readdir path, (err, files) ->
    throw next new NotFound(path) if err?
    filtered_files = _.filter files, (file) ->
      file.indexOf(filename) isnt -1
    if filtered_files.length is 1
      fs.readFile "#{path}/#{filtered_files[0]}", "utf-8", (err, data) ->
        callback filtered_files[0].substring(0, filtered_files[0].indexOf(".")), data
    else
      callback

redirect_to_presentation = (req, res, catalog, filename) ->
  catalog_path = "#{__dirname}/../#{catalog}"
  find_file catalog_path, filename, (filename, data) ->
    data = JSON.parse data
    if data.alias_of
      res.redirect "/#{catalog}/#{data.alias_of}", 301
    else
      res.redirect "/#{catalog}/#{filename}", 301

exports.redirect_to_catalog_if_subdomain = () ->
  third_level_domain_regex = /([\w]+)\.[\w]+\..+/
  return (req, res, next) ->
    proxy = req.headers["x-forwarded-host"]
    if proxy?
      match = proxy.match third_level_domain_regex
      if match?
        res.redirect "http://#{proxy.replace("#{match[1]}.", "")}/#{match[1]}#{req.url}", 302

exports.redirect_to_presentation_from_html = (req, res, next) ->
  console.log "redirect_to_presentation_from_html"
  redirect_to_presentation req, res, req.params.catalog_name, req.params.presentation

exports.redirect_to_presentation_from_p_html = (req, res, next) ->
  console.log "redirect_to_presentation_from_p"

  if req.query.p.indexOf("/") is -1
    catalog_name = req.params.catalog_name
    filename = req.query.p
  else
    catalog_name = req.query.p.substr(0, req.query.p.indexOf("/"))
    filename = req.query.p.substr(req.query.p.indexOf("/") + 1)

  redirect_to_presentation req, res, catalog_name, filename

exports.redirect_to = (url) ->
  return (req, res, next) ->
    res.redirect 302, url
