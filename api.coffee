###
Presentz.org - A website to publish presentations with video and slides synchronized.

Copyright (C) 2012 Federico Fissore

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

"use strict"

http = require "http"
https = require "https"
xml2json = require "xml2json"
node_slideshare = require "slideshare"
utils = require "./utils"
_ = require "underscore"
url = require "url"

storage = null
slideshare = null

init = (s, slideshare_conf) ->
  storage = s
  slideshare = new node_slideshare slideshare_conf.api_key, slideshare_conf.shared_secret

safe_next = (next, err) ->
  err = new Error(err) if !(err instanceof Error)
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

presentation_save_published = (presentation, callback) ->
  allowed_fields = [ "@class", "@type", "title", "speaker", "_type", "published", "id", "in", "out", "@version", "@rid" ]

  utils.ensure_only_wanted_fields_in presentation, allowed_fields

  storage.save presentation, callback

presentation_save_everything = (user, presentation, callback) ->
  allowed_map_of_fields =
    presentation: [ "@class", "@type", "@version", "@rid", "in", "out", "id", "title", "time", "speaker", "_type", "published", "chapters" ]
    chapter: [ "@class", "@type", "@version", "@rid", "in", "out", "duration", "_type", "_index", "video", "slides" ]
    video: [ "url", "thumb" ]
    slide: [ "@class", "@type", "@version", "@rid", "in", "out", "url", "title", "time", "_type", "public_url" ]

  utils.visit_presentation presentation, utils.ensure_only_wanted_map_of_fields_in, allowed_map_of_fields

  save = (obj, callback) ->
    is_new = !obj["@rid"]?
    cb = (err, obj) ->
      return callback(err) if err?
      obj.is_new = is_new
      callback(undefined, obj, is_new)

    if is_new
      storage.create obj, cb
    else
      storage.save obj, cb

  link_all_new = (objs, node_to_link_to, storage_function, callback) ->
    new_objs = _.filter objs, (obj) -> obj.is_new? and obj.is_new

    return callback(undefined) if new_objs.length is 0

    linked_objs = []
    for obj in new_objs
      storage_function obj, node_to_link_to, (err, link) ->
        return callback(err) if err?
        linked_objs.push(link)
        return callback(undefined) if linked_objs.length is new_objs.length

  save_all_slides = (slides, callback) ->
    return callback(undefined, []) if slides.length is 0

    saved_slides = []
    for slide in slides
      slide["@class"] ?= "V"
      slide["@type"] ?= "d"
      slide._type ?= "slide"

      save slide, (err, slide) ->
        return callback(err) if err?
        saved_slides.push(slide)
        return callback(undefined, saved_slides) if saved_slides.length is slides.length

  save_all_chapters = (chapters, callback) ->
    return callback(undefined, []) if chapters.length is 0
    saved_chapters = []
    for chapter in chapters
      chapter["@class"] ?= "V"
      chapter["@type"] ?= "d"
      chapter._type ?= "chapter"

      save_all_slides chapter.slides, (err, slides) ->
        return callback(err) if err?
        delete chapter.slides
        save chapter, (err, chapter) ->
          return callback(err) if err?
          link_all_new slides, chapter, storage.link_slide_to_chapter, (err) ->
            return callback(err) if err?
            saved_chapters.push(chapter)
            return callback(undefined, saved_chapters) if saved_chapters.length is chapters.length

  presentation["@class"] ?= "V"
  presentation["@type"] ?= "d"
  presentation._type ?= "presentation"

  save_all_chapters presentation.chapters, (err, chapters) ->
    return callback(err) if err?
    delete presentation.chapters
    save presentation, (err, presentation, was_new) ->
      return callback(err) if err?
      link_all_new chapters, presentation, storage.link_chapter_to_presentation, (err) ->
        return callback(err) if err?

        storage.link_user_to_presentation user, presentation, (err) ->
          return callback(err) if err?

          storage.load_entire_presentation_from_id presentation.id, callback

presentation_save = (req, res, next) ->
  presentation = req.body

  callback = (err, new_presentation) ->
    return safe_next(next, err) if err?

    res.send new_presentation

  if has_slides(presentation)
    presentation_save_everything(req.user, presentation, callback)
  else
    presentation_save_published(presentation, callback)

presentation_load = (req, res, next) ->
  storage.load_entire_presentation_from_id req.params.presentation, (err, presentation) ->
    return safe_next(next, err) if err?

    res.send presentation

slideshare_slides_of = (req, res, next) ->
  request_params =
    host: "cdn.slidesharecdn.com"
    path: "/#{req.params.doc_id}.xml"

  request = http.request request_params, (response) ->
    response.setEncoding "utf8"
    xml = ""
    response.on "data", (chunk) ->
      xml = xml.concat(chunk)
    response.on "end", () ->
      res.contentType "application/json"
      slides = JSON.parse(xml2json.toJson(xml))
      for slide in slides.Show.Slide
        slide.Src = slide.Src.replace("http://slideshare.s3.amazonaws.com", "http://cdn.slidesharecdn.com")
      res.send slides

  request.on "error", (e) ->
    console.warn arguments
    res.render {}

  request.end()

slideshare_url_to_doc_id = (req, res, next) ->
  slideshare.getSlideshowByURL req.query.url, { detailed: 1 }, (xml) ->
    res.contentType "application/json"
    res.send xml2json.toJson(xml)

speaker_deck_data_id_regexp = /data-id="([0-9a-zA-Z]+)"/

speakerdeck_url_to_data_id = (req, res, next) ->
  request_params =
    host: "speakerdeck.com"
    path: url.parse(req.query.url).pathname

  request = https.request request_params, (response) ->
    return res.send 500, "Unable to find data-id" if response.statusCode isnt 200
    
    response.setEncoding "utf8"
    html = ""
    response.on "data", (chunk) ->
      html = html.concat(chunk)
    response.on "end", () ->
      matches = html.match speaker_deck_data_id_regexp

      return res.send 500, "Unable to find data-id" if !matches? or matches.length < 2

      res.send { data_id: matches[1] }

  request.on "error", (e) ->
    console.warn arguments
    res.render {}

  request.end()


delete_slide = (req, res, next) ->
  storage.delete_slide req.params.node_id, (err) ->
    return next(err) if err?

    res.send 200

exports.init = init
exports.presentations = presentations
exports.presentation_save = presentation_save
exports.presentation_load = presentation_load
exports.slideshare_slides_of = slideshare_slides_of
exports.slideshare_url_to_doc_id = slideshare_url_to_doc_id
exports.speakerdeck_url_to_data_id = speakerdeck_url_to_data_id
exports.delete_slide = delete_slide