http = require "http"
xml2json = require "xml2json"
node_slideshare = require "slideshare"
utils = require "./utils"

storage = null
slideshare = null

init = (s, slideshare_conf) ->
  storage = s
  slideshare = new node_slideshare slideshare_conf.api_key, slideshare_conf.shared_secret

safe_next = (next, err) ->
  err = new Error(err) if utils.type_of(err) isnt "error"
  next(err)

presentations = (req, res, next) ->
  storage.from_user_to_presentations req.user, (err, presentations) ->
    return safe_next(next, err) if err?

    res.send presentations

has_slides = (presentation) ->
  return false if !presentation.chapters?

  for chapter in presentation.chapters
    return true if chapter.slides?

  false

presentation_update_published = (presentation, callback) ->
  allowed_fields = [ "@class", "@type", "title", "speaker", "_type", "published", "id", "in", "out", "@version", "@rid" ]

  utils.ensure_only_wanted_fields_in presentation, allowed_fields

  storage.save presentation, callback

presentation_update_everything = (presentation, callback) ->
  allowed_map_of_fields =
    presentation: [ "@class", "@type", "@version", "@rid", "in", "out", "id", "title", "time", "speaker", "_type", "published", "chapters" ]
    chapter: [ "@class", "@type", "@version", "@rid", "in", "out", "duration", "_type", "_index", "video", "slides" ]
    video: [ "url", "thumb" ]
    slide: [ "@class", "@type", "@version", "@rid", "in", "out", "url", "title", "time", "_type", "public_url" ]

  utils.visit_presentation presentation, utils.ensure_only_wanted_map_of_fields_in, allowed_map_of_fields
  
  storage.cascading_save presentation, callback

presentation_update = (req, res, next) ->
  presentation = req.body

  callback = (err, new_presentation) ->
    return safe_next(next, err) if err?

    res.send new_presentation

  if has_slides(presentation)
    presentation_update_everything(presentation, callback)
  else
    presentation_update_published(presentation, callback)

presentation_load = (req, res, next) ->
  storage.load_entire_presentation_from_id req.params.presentation, (err, presentation) ->
    return safe_next(next, err) if err? 

    res.send presentation

slideshare_slides_of = (req, res, next) ->
  request_params =
    host: "cdn.slidesharecdn.com"
    port: 80
    path: "/#{req.params.doc_id}.xml"

  request = http.request request_params, (response) ->
    response.setEncoding "utf8"
    xml = ""
    response.on "data", (chunk) ->
      xml = xml.concat(chunk)
    response.on "end", () ->
      res.contentType "application/json"
      res.send xml2json.toJson(xml)

  request.on "error", (e) ->
    console.warn arguments
    res.render {}

  request.end()

slideshare_url_to_doc_id = (req, res, next) ->
  slideshare.getSlideshowByURL req.query.url, { detailed: 1 }, (xml) ->
    res.contentType "application/json"
    res.send xml2json.toJson(xml)

exports.init = init
exports.presentations = presentations
exports.presentation_update = presentation_update
exports.presentation_load = presentation_load
exports.slideshare_slides_of = slideshare_slides_of
exports.slideshare_url_to_doc_id = slideshare_url_to_doc_id