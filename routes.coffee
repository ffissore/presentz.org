_ = require "underscore"
dateutil = require "dateutil"
moment = require "moment"

utils = require "./utils"
storage = require "./storage"
dustjs_helpers = require "./dustjs_helpers"
draw_4_boxes = dustjs_helpers.draw_boxes(4)
draw_6_boxes = dustjs_helpers.draw_boxes(6)

db = undefined

pretty_duration = (seconds, minutes_char = "'", seconds_char = "\"") ->
  duration = moment.duration(Math.round(seconds), "seconds")
  "#{duration.minutes().pad(2)}#{minutes_char}#{duration.seconds().pad(2)}#{seconds_char}"

list_catalogs = (req, res, next) ->
  number_of_presentations = (catalog, callback) ->
    db.getInEdges catalog, "part_of", (err, edges) ->
      return next(err) if err?
      catalog.presentations_length = edges.length
      callback(undefined, catalog)

  db.command "SELECT FROM V WHERE _type = 'catalog' and (hidden is null or hidden = 'false') ORDER BY name", (err, catalogs) ->
    return next(err) if err?

    utils.exec_for_each number_of_presentations, catalogs, (err) ->
      return next(err) if err?
      res.render "catalogs",
        title: "Presentz talks"
        css_section_talks: "class=\"selected\""
        catalogs: catalogs
        list: draw_6_boxes

show_catalog = (req, res, next) ->
  pres_to_thumb= (presentation, catalog_name) ->
    pres =
      id: presentation.id
      catalog: catalog_name
      thumb: presentation.chapters[0].video.thumb
      speaker: presentation.speaker
      title: presentation.title

    pres.time = dateutil.format(dateutil.parse(presentation.time, "YYYYMMDD"), "Y/m") if presentation.time
    pres

  db.command "SELECT FROM V WHERE _type = 'catalog' and id = '#{req.params.catalog_name}'", (err, results) ->
    return next(err) if err?
    return next("no record found") if results.length is 0

    catalog = results[0]
    db.fromVertex(catalog).inVertexes "part_of", (err, presentations) ->
      return next(err) if err?

      utils.exec_for_each storage.load_chapters_of, presentations, (err) ->
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
          list: draw_4_boxes

raw_presentation = (req, res, next) ->
  wipe_out_storage_fields = (presentation) ->
    wipe_out_from_comments_in = (element) ->
      for comment in element.comments
        wipe_out_from comment
        delete comment.user

    wipe_out_from= (element) ->
      delete element.in
      delete element.out
      delete element._type
      delete element._index
      delete element["@class"]
      delete element["@type"]
      delete element["@version"]
      delete element["@rid"]

    wipe_out_from presentation
    wipe_out_from_comments_in presentation
    for chapter in presentation.chapters
      wipe_out_from chapter
      for slide in chapter.slides
        wipe_out_from slide
        wipe_out_from_comments_in slide

  path = decodeURIComponent(req.path).substring(1)
  path = path.substring(0, path.length - ".json".length)
  storage.load_entire_presentation_from_path path, (err, presentation) ->
    return next(err) if err?

    wipe_out_storage_fields presentation

    if req.query.jsoncallback
      presentation = "#{req.query.jsoncallback}(#{JSON.stringify(presentation)});"
      res.contentType("text/javascript")
    else
      res.contentType("application/json")

    res.send presentation

show_presentation = (req, res, next) ->
  comments_of = (presentation) ->
    comments = []
    for comment in presentation.comments
      comment.nice_time = moment(comment.time).fromNow()
      comments.push comment

    chapter_index = 0
    for chapter in presentation.chapters
      slide_index = 0
      for slide in chapter.slides
        for comment in slide.comments
          comment.slide_title = slide.title or "Slide #{slide_index + 1}"
          comment.nice_time = moment(comment.time).fromNow()
          comment.slide_index = slide_index
          comment.chapter_index = chapter_index
          comments.push comment
        slide_index++
      chapter_index++

    comments

  slide_to_slide = (slide, chapter_index, slide_index, duration) ->
    slide.title = "Slide #{ slide_index + 1 }" if !slide.title?
    slide.chapter_index = chapter_index
    slide.slide_index = slide_index
    slide.time = slide.time + duration
    if slide.comments?
      slide.comments_length = slide.comments.length
    else
      slide.comments_length = 0
    if slide.comments_length is 1
      slide.comments_label = "comment"
    else
      slide.comments_label = "comments"
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
      slide.duration = pretty_duration slide.duration
      slide.index = (slide_num + 1).pad(number_of_zeros_in_index)
      slide.css = "class=\"even\"" if slide.index % 2 is 0

  path = decodeURIComponent(req.path).substring(1)
  storage.load_entire_presentation_from_path path, (err, presentation) ->
    return next(err) if err?

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

    comments = comments_of presentation

    res.render "presentation",
      title: pres_title
      talk_title: talk_title
      speaker: presentation.speaker
      slides: slides
      comments: comments
      domain: "http://#{req.headers["x-forwarded-host"] or req.headers.host}"
      path: path
      thumb: presentation.chapters[0].video.thumb
      wrapper_css: "class=\"section_player\""
      embed: req.query.embed?

comment_presentation = (req, res, next) ->
  params = req.body

  get_node_to_link_to = (callback) ->
    path = decodeURIComponent(req.path).substring(1)
    path = path.substring(0, path.lastIndexOf("/"))

    storage.load_entire_presentation_from_path path, (err, presentation) ->
      return callback(err) if err?

      node_to_link_to = presentation

      if params.chapter? and params.chapter isnt "" and params.slide? and params.slide isnt ""
        node_to_link_to = presentation.chapters[params.chapter].slides[params.slide]

      callback(undefined, node_to_link_to)

  save_and_link_comment = (node_to_link_to, callback) ->
    comment =
      _type: "comment"
      text: params.comment
      time: new Date()

    db.createVertex comment, (err, comment) ->
      return callback(err) if err?
      db.createEdge comment, node_to_link_to, { label: "comment_of" }, (err) ->
        return callback(err) if err?
        db.createEdge req.user, comment, { label: "authored_comment" }, (err) ->
          return callback(err) if err?
          callback(undefined, comment)

  get_node_to_link_to (err, node_to_link_to) ->
    return next(err) if err?

    save_and_link_comment node_to_link_to, (err, comment) ->
      comment.user = req.user
      comment.chapter_index = params.chapter
      comment.slide_index = params.slide
      comment.nice_time = moment(comment.time).fromNow()
      if node_to_link_to._type is "slide"
        comment.slide_title = node_to_link_to.title or "Slide #{parseInt(params.slide) + 1}"

      if err?
        res.send 500
      else
        res.render "_comment_",
          comment: comment

static_view = (view_name) ->
  return (req, res) ->
    options =
      title: "Presentz"
    options["css_section_#{view_name}"] = "class=\"selected\""
    res.render view_name, options

ensure_is_logged = (req, res, next) ->
  return next() if req.user?

  #req.notify "error", "you need to be logged in"
  res.redirect 302, "/"

exports.raw_presentation = raw_presentation
exports.show_catalog = show_catalog
exports.list_catalogs = list_catalogs
exports.show_presentation = show_presentation
exports.comment_presentation = comment_presentation
exports.static_view = static_view
exports.ensure_is_logged = ensure_is_logged
exports.init = (database) ->
  db = database
  storage.init database
  @

