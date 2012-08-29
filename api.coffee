http = require "http"
xml2json = require "xml2json"
node_slideshare = require "slideshare"

storage = null
slideshare = null

init = (s, slideshare_conf) ->
  storage = s
  slideshare = new node_slideshare slideshare_conf.api_key, slideshare_conf.shared_secret

beautify_slide_urls = (presentation, callback) ->
  callback()

presentations = (req, res, next) ->
  storage.from_user_to_presentations req.user, (err, presentations) ->
    return next(err) if err?

    res.send presentations

presentation_update_published = (presentation, callback) ->
  delete presentation.chapters

  storage.save presentation, callback

presentation_update_everything = (presentation, callback) ->
  callback("unsupported")

has_slides = (presentation) ->
  return false if !presentation.chapters?
  
  for chapter in presentation.chapters
    return true if chapter.slides?
    
  false
  
presentation_update = (req, res, next) ->
  presentation = req.body

  callback = (err) ->
    return next(err) if err?

    res.send 200

  if has_slides(presentation)
    presentation_update_everything(presentation, callback)
  else
    presentation_update_published(presentation, callback)

presentation_load = (req, res, next) ->
  storage.load_entire_presentation_from_id req.params.presentation, (err, presentation) ->
    return next(err) if err?

    beautify_slide_urls presentation, (err) ->
      return next(err) if err?

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

###
exports.mines_authored= (req, res) ->
  api.db.fromVertex(req.user).outVertexes "authored", (err, presentations) ->
    for p in presentations
      delete p.chapters

    res.send presentations

exports.mines_held= ->
  throw new Error
###