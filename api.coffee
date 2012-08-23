http = require "http"
xml2json = require "xml2json"

storage = null

init = (s) ->
  storage = s

beautify_slide_urls = (presentation, callback) ->
  callback()

presentations = (req, res, next) ->
  storage.from_user_to_presentations req.user, (err, presentations) ->
    return next(err) if err?

    for presentation in presentations
      storage.remove_storage_fields_from_presentation presentation

    res.send presentations

presentation_update = (req, res, next) ->
  new_presentation = req.body
  storage.load_presentation_from_id req.params.presentation, (err, presentation) ->
    return next(err) if err?

    presentation.published = new_presentation.published

    storage.save presentation, (err, presentation) ->
      return next(err) if err?

      res.send 200

presentation_load = (req, res, next) ->
  storage.load_entire_presentation_from_id req.params.presentation, (err, presentation) ->
    return next(err) if err?

    beautify_slide_urls presentation, (err) ->
      return next(err) if err?

      res.send presentation

slideshare_info = (req, res, next) ->
  request_params =
    host: "cdn.slidesharecdn.com"
    port: 80
    path: "/#{req.params.doc_id}.xml"
    agent: false
    headers:
      "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:14.0) Gecko/20100101 Firefox/14.0.1"
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      "Accept-Language": "it-it,it;q=0.8,en-us;q=0.5,en;q=0.3"
      "Accept-Encoding": "gzip, deflate"
      "Referer": "http://static.slidesharecdn.com/swf/ssplayer2.swf"

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

exports.init = init
exports.presentations = presentations
exports.presentation_update = presentation_update
exports.presentation_load = presentation_load
exports.slideshare_info = slideshare_info

###
exports.mines_authored= (req, res) ->
  api.db.fromVertex(req.user).outVertexes "authored", (err, presentations) ->
    for p in presentations
      delete p.chapters

    res.send presentations

exports.mines_held= ->
  throw new Error
###