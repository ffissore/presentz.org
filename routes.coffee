fs = require "fs"
path = require "path"
_ = require "underscore"
_s = require "underscore.string"
http = require "http"
url = require "url"
dateutil = require "dateutil"
moment = require "moment"

routes = {}

draw_boxes = (number_of_boxes) ->
  return (chunk, context, bodies) ->
    presentations = context.current()
    index = 0
    for presentation in presentations
      index++
      chunk = chunk.render(bodies.block, context.push(presentation))
      if index is number_of_boxes
        chunk = chunk.write("<div class=\"clear\"></div>")
        index = 0
    return chunk

pres_to_thumb = (presentation, catalog_name) ->
  pres =
    id: presentation.id
    catalog: catalog_name
    thumb: presentation.chapters[0].media.video.thumb
    speaker: presentation.speaker
    title: presentation.title

  pres.time = dateutil.format(dateutil.parse(presentation.time, "YYYYMMDD"), "Y/m") if presentation.time
  pres

load_presentation_from_path = (path, callback) ->
  path_parts = path.split("/")
  catalog_name = path_parts[0]
  presentation_name = path_parts[1]

  query = "select from V where _type = 'presentation' and id = '#{presentation_name}' and out.label CONTAINSALL 'part_of' and out.in.id CONTAINSALL '#{catalog_name}'"
  routes.db.command query, (err, results) ->
    return callback(err) if err?
    return callback("no record found") if results.length is 0
    callback(undefined, results[0])

exports.init = (db) ->
  routes.db = db
  @

exports.list_catalogs = (req, res, next) ->
  routes.db.command "SELECT FROM V WHERE _type = 'catalog' and (hidden is null or hidden = 'false') ORDER BY name", (err, results) ->
    return next(err) if err?
    catalogs = []

    number_of_presentations = (catalog, callback) ->
      routes.db.getInEdges catalog, "part_of", (err, edges) ->
        return next(err) if err?
        catalog.presentations = edges.length
        catalogs.push catalog

        if catalogs.length is results.length
          return callback()

    for catalog in results
      number_of_presentations catalog, ->
        res.render "catalogs",
          title: "Presentz talks"
          section: "talks"
          catalogs: catalogs
          list: draw_boxes(6)

exports.show_catalog = (req, res, next) ->
  routes.db.command "SELECT FROM V WHERE _type = 'catalog' and id = '#{req.params.catalog_name}'", (err, results) ->
    return next(err) if err?
    return next("no record found") if results.length is 0

    catalog = results[0]
    routes.db.fromVertex(catalog).inVertexes "part_of", (err, presentations) ->
      return next(err) if err?

      presentations = (pres_to_thumb(pres, req.params.catalog_name) for pres in presentations when !pres.alias_of?)
      presentations = _.sortBy presentations, (presentation) ->
        return presentation.time if presentation.time?
        return presentation.title
      if presentations[0].time?
        presentations = presentations.reverse()

      res.render "talks",
        title: "#{catalog.name} talks"
        catalog: catalog
        presentations: presentations
        list: draw_boxes(4)

exports.raw_presentation = (req, res, next) ->
  path = decodeURIComponent(req.path).substring(1)
  path = path.substring(0, path.length - ".json".length)
  load_presentation_from_path path, (err, presentation) ->
    return next(err) if err?
    presentation = "#{req.query.jsoncallback}(#{JSON.stringify(presentation)});" if req.query.jsoncallback
    res.send presentation

exports.show_presentation = (req, res, next) ->
  path = decodeURIComponent(req.path).substring(1)
  load_presentation_from_path path, (err, presentation) ->
    return next(err) if err?

    duration = _.reduce (chapter.duration for chapter in presentation.chapters), (one, two) -> one + two
    slides = []
    duration = 0
    for chapter in presentation.chapters
      for slide in chapter.media.slides
        slide = _.clone slide
        delete slide.url
        slide.time = slide.time + duration
        slides.push slide
      duration += chapter.duration
    percent_per_second = 100 / duration
    width_used = 0
    for slide_num in [0...slides.length]
      slide = slides[slide_num]
      if slide_num + 1 < slides.length
        slide.duration = (slides[slide_num + 1].time - slide.time)
        slide.width = slide.duration * percent_per_second
        slide.width = 0.25 if slide.width < 0.25
        width_used += slide.width
        slide.width = "#{slide.width.toFixed(2)}%"
      else
        slide.duration = duration - slide.time
        slide.width = "#{(100 - width_used).toFixed(2)}%"
      pretty_duration = moment.duration(slide.duration, "seconds")
      slide.duration = "#{pretty_duration.minutes()}'#{pretty_duration.seconds()}\""

    title_parts = presentation.title.split(" ")
    title_parts[title_parts.length - 1] = "<span>#{title_parts[title_parts.length - 1]}</span>"
    talk_title = title_parts.join(" ")
    res.render "presentation",
      title: "#{presentation.title} - #{presentation.speaker}"
      talk_title: talk_title
      speaker: presentation.speaker
      slides: slides
      #catalog: catalog
      url: "#{req.url_original || req.url}.json"
      thumb: presentation.chapters[0].media.video.thumb

exports.static = (view_name) ->
  return (req, res) ->
    res.render view_name,
      title: "Presentz"
      section: view_name

fill_presentation_data_from_file = (file, file_name, catalog_id, callback) ->
  fs.readFile file, "utf-8", (err, data) ->
    data = JSON.parse data

    return callback(data) if data.alias_of?

    pres =
      id: "/#{catalog_id}/#{file_name.substring(0, file_name.indexOf("."))}"
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

###
exports.show_catalog = (req, res, next) ->
  console.log "show_catalog"
  catalog_path = "#{__dirname}/#{req.params.catalog_name}"
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
  catalog_path = "#{__dirname}/#{req.params.catalog_name}"
  catalog_id = req.params.catalog_name
  read_catalog catalog_path, catalog_id, (err, catalog) ->
    return next(err) if err?

    fs.readFile "#{__dirname}/#{decodeURIComponent(req.path)}.json", "utf-8", (err, data) ->
      return next(err) if err?

      pres = JSON.parse data
      res.render "presentation",
        title: pres.title_long || pres.title
        catalog: catalog
        url: "#{req.url_original || req.url}.json"
        thumb: pres.chapters[0].media.video.thumb

exports.raw_presentation = (req, res, next) ->
  console.log "raw_presentation"

  fs.readFile "#{__dirname}/#{decodeURIComponent(req.path)}", "utf-8", (err, data) ->
    return next(err) if err?

    data = "#{req.query.jsoncallback}(#{data});" if req.query.jsoncallback
    res.send data
###

exports.ensure_is_logged = (req, res, next) ->
  return next() if req.user

  req.notify "error", "you need to be logged in"
  res.redirect 302, "/"
