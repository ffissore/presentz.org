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
    thumb: presentation.chapters[0].video.thumb
    speaker: presentation.speaker
    title: presentation.title

  pres.time = dateutil.format(dateutil.parse(presentation.time, "YYYYMMDD"), "Y/m") if presentation.time
  pres
  
slide_to_slide = (slide, chapter_index, slide_index, duration) ->
  slide = _.clone(slide)
  delete slide.url
  slide.title = "Slide #{ slide_index + 1 }" if !slide.title?
  slide.chapter_index = chapter_index
  slide.slide_index = slide_index
  slide.time = slide.time + duration
  slide
  
slides_duration_percentage_css = (slides, duration) ->
  percent_per_second = 100 / duration
  percent_used = 0
  duration_used = 0
  number_of_zeros_in_index = slides.length.toString().length
  for slide_num in [0...slides.length]
    slide = slides[slide_num]
    if slide_num + 1 < slides.length
      slide.duration = slides[slide_num + 1].time - slide.time
      slide.percentage = slide.duration * percent_per_second
      percent_used += slide.percentage
    else
      slide.duration = duration - slide.time
      slide.percentage = 100 - percent_used
    duration_used += slide.duration
    percent_per_second = (100 - percent_used) / (duration - duration_used)
    pretty_duration = moment.duration(Math.round(slide.duration), "seconds")
    slide.duration = "#{pretty_duration.minutes()}'#{pretty_duration.seconds()}\""
    slide.index = (slide_num + 1).pad(number_of_zeros_in_index)
    slide.css = "class=\"even\"" if slide.index % 2 is 0


load_presentation_from_path = (path, callback) ->
  path_parts = path.split("/")
  catalog_name = path_parts[0]
  presentation_name = path_parts[1]

  query = "select from V where _type = 'presentation' and id = '#{presentation_name}' and out.label CONTAINSALL 'part_of' and out.in.id CONTAINSALL '#{catalog_name}'"
  routes.db.command query, (err, results) ->
    return callback(err) if err?
    return callback("no record found") if results.length is 0
    callback(undefined, results[0])

load_chapters_of = (presentations, callback) ->
  loaded_presentations = []

  chapter_of = (presentation) ->
    routes.db.fromVertex(presentation).inVertexes "chapter_of", (err, chapters) ->
      return callback(err) if err?
      presentation.chapters = _.sortBy chapters, (chapter) -> chapter._index
      loaded_presentations.push presentation
      return callback() if loaded_presentations.length is presentations.length

  chapter_of(presentation) for presentation in presentations

load_slides_of = (chapters, callback) ->
  loaded_chapters = []

  slides_of = (chapter) ->
    routes.db.fromVertex(chapter).inVertexes "slide_of", (err, slides) ->
      return callback(err) if err?
      chapter.slides = _.sortBy slides, (slide) -> slide.time
      loaded_chapters.push chapter
      return callback() if loaded_chapters.length is chapters.length

  slides_of(chapter) for chapter in chapters

load_entire_presentation_from_path = (path, callback) ->
  load_presentation_from_path path, (err, presentation) ->
    return callback(err) if err?
    load_chapters_of [presentation], (err) ->
      return callback(err) if err?
      load_slides_of presentation.chapters, (err) ->
        return callback(err) if err?
        return callback(undefined, presentation)

number_of_presentations = (catalog, catalogs, number_of_catalogs, callback) ->
  routes.db.getInEdges catalog, "part_of", (err, edges) ->
    return next(err) if err?
    catalog.presentations = edges.length
    catalogs.push catalog

    return callback() if catalogs.length is number_of_catalogs

wipe_out_storage_fields = (presentation) ->
  wipe_out_from = (element) ->
    delete element.in
    delete element.out
    delete element._type
    delete element["@class"]
    delete element["@type"]
    delete element["@version"]
    delete element["@rid"]

  wipe_out_from presentation
  for chapter in presentation.chapters
    wipe_out_from chapter
    for slide in chapter.slides
      wipe_out_from slide

exports.init = (db) ->
  routes.db = db
  @

exports.list_catalogs = (req, res, next) ->
  routes.db.command "SELECT FROM V WHERE _type = 'catalog' and (hidden is null or hidden = 'false') ORDER BY name", (err, results) ->
    return next(err) if err?
    
    catalogs = []

    for catalog in results
      number_of_presentations catalog, catalogs, results.length, ->
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

      load_chapters_of presentations, (err) ->
        return next(err) if err?
        presentations = (pres_to_thumb(pres, req.params.catalog_name) for pres in presentations)
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
  load_entire_presentation_from_path path, (err, presentation) ->
    return next(err) if err?

    wipe_out_storage_fields presentation

    if req.query.jsoncallback
      presentation = "#{req.query.jsoncallback}(#{JSON.stringify(presentation)});"
      res.contentType("text/javascript")
    else
      res.contentType("application/json")
    res.send presentation

exports.show_presentation = (req, res, next) ->
  path = decodeURIComponent(req.path).substring(1)
  load_entire_presentation_from_path path, (err, presentation) ->
    return next(err) if err?

    duration = _.reduce (chapter.duration for chapter in presentation.chapters), (one, two) -> one + two
    slides = []
    duration = 0
    for chapter_index in [0...presentation.chapters.length]
      chapter = presentation.chapters[chapter_index]
      for slide_index in [0...chapter.slides.length]
        slides.push slide_to_slide(chapter.slides[slide_index], chapter_index, slide_index, duration)
      duration += chapter.duration

    slides_duration_percentage_css(slides, duration)

    title_parts = presentation.title.split(" ")
    title_parts[title_parts.length - 1] = "<span>#{title_parts[title_parts.length - 1]}</span>"
    talk_title = title_parts.join(" ")
    pres_title = presentation.title
    pres_title = "#{pres_title} - #{presentation.speaker}" if presentation.speaker?
    res.render "presentation",
      title: pres_title
      talk_title: talk_title
      speaker: presentation.speaker
      slides: slides
      #catalog: catalog
      to_json_url: "#{req.url_original || req.url}.json"
      thumb: presentation.chapters[0].video.thumb

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
      thumb: data.chapters[0].video.thumb

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
