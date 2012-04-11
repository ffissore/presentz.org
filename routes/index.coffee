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

fill_presentation_data_from_file = (file, file_name, catalog_id, callback) ->
  fs.readFile file, "utf-8", (err, data) ->
    data = JSON.parse data

    return callback(data) if data.alias_of?

    pres =
      id: "/#{catalog_id}/#{file_name.substr(0, file_name.indexOf("."))}"
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

    callback(undefined, pres)

collect_presentations = (files, catalog_path, catalog_id, callback) ->
  files = (file for file in files when !_s.startsWith(file, "catalog") and _s.endsWith(file, ".json"))
  presentations = []
  computed_files = []
  for file in files
    fill_presentation_data_from_file "#{catalog_path}/#{file}", file, catalog_id, (invalid, pres) ->
      computed_files.push file

      return if invalid?

      presentations.push pres
      callback(undefined, presentations) if files.length is computed_files.length
  return

read_catalog = (catalog_path, catalog_id, callback) ->
  fs.readFile "#{catalog_path}/catalog.json", "utf-8", (err, data) ->
    return callback(err) if err?

    catalog = JSON.parse data
    catalog.id = catalog_id
    callback(undefined, catalog)

exports.static = (view_name) ->
  return (req, res) ->
    res.render view_name,
      title: "Presentz"

exports.show_catalog = (req, res, next) ->
  console.log "show_catalog"
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  path.exists catalog_path, (exists) ->
    catalog_id = req.params.catalog_name
    read_catalog catalog_path, catalog_id, (err, catalog) ->
      return next(err) if err?

      fs.readdir catalog_path, (err, files) ->
        return next(err) if err?

        collect_presentations files, catalog_path, catalog_id, (err, presentations) ->
          presentations = _.sortBy presentations, (pres) ->
            pres.id
          presentations = presentations.reverse()
          res.render "catalog",
            title: "#{catalog.name} is on Presentz",
            catalog: catalog
            presentations: presentations

exports.show_presentation = (req, res, next) ->
  console.log "show_presentation"
  catalog_path = "#{__dirname}/../#{req.params.catalog_name}"
  catalog_id = req.params.catalog_name
  read_catalog catalog_path, catalog_id, (err, catalog) ->
    return next(err) if err?

    fs.readFile "#{__dirname}/..#{req.path}.json", "utf-8", (err, data) ->
      return next(err) if err?

      pres = JSON.parse data
      res.render "presentation",
        title: pres.title_long || pres.title
        catalog: catalog
        url: "#{req.url_original || req.url}.json"
        thumb: pres.chapters[0].media.video.thumb

exports.raw_presentation = (req, res, next) ->
  console.log "raw_presentation"

  fs.readFile "#{__dirname}/..#{req.path}", "utf-8", (err, data) ->
    return next(err) if err?

    data = "#{req.query.jsoncallback}(#{data});" if req.query.jsoncallback
    res.send data