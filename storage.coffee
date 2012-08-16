utils = require "./utils"
_ = require "underscore"

db = null

init = (database) ->
  db = database
  @

save = (document, callback) ->
  db.save document, callback

count_presentations_in_catalog = (catalog, callback) ->
  db.getInEdges catalog, "part_of", (err, edges) ->
    return next(err) if err?
    catalog.presentations_length = edges.length
    callback(undefined, catalog)

list_catalogs_with_presentation_count = (callback) ->
  db.command "SELECT FROM V WHERE _type = 'catalog' and (hidden is null or hidden = 'false') ORDER BY name", (err, catalogs) ->
    return callback(err) if err?

    utils.exec_for_each count_presentations_in_catalog, catalogs, (err) ->
      return callback(err) if err?
      callback(undefined, catalogs)

catalog_name_to_node = (name, callback) ->
  db.command "SELECT FROM V WHERE _type = 'catalog' and id = '#{name}'", (err, catalogs) ->
    return callback(err) if err?
    return callback("no record found") if catalogs.length is 0

    callback(undefined, catalogs[0])

from_catalog_to_presentations = (catalog, callback) ->
  db.fromVertex(catalog).inVertexes "part_of", (err, presentations) ->
    return callback(err) if err?

    utils.exec_for_each load_chapters_of, presentations, (err) ->
      return callback(err) if err?

      callback(undefined, presentations)

from_user_to_presentations = (user, callback) ->
  db.fromVertex(user).outVertexes "authored", (err, presentations) ->
    return callback(err) if err?

    utils.exec_for_each load_chapters_of, presentations, (err) ->
      return callback(err) if err?

      callback(undefined, presentations)

create_comment = (comment, node_to_link_to, user, callback) ->
  db.createVertex comment, (err, comment) ->
    return callback(err) if err?

    db.createEdge comment, node_to_link_to, { label: "comment_of" }, (err) ->
      return callback(err) if err?

      db.createEdge user, comment, { label: "authored_comment" }, (err) ->
        return callback(err) if err?

        callback(undefined, comment)

load_presentation_from_id = (id, callback) ->
  db.command "select from V where _type = 'presentation' and id = '#{id}'", (err, results) ->
    return callback(err) if err?
    return callback("no record found") if results.length is 0
    callback(undefined, results[0])

load_entire_presentation_with_query = (query, callback) ->
  db.command query, (err, results) ->
    return callback(err) if err?
    return callback("no record found") if results.length is 0
    
    presentation = results[0]
    load_comments_of presentation, (err) ->
      return callback(err) if err?
      
      load_chapters_of presentation, (err) ->
        return callback(err) if err?

        utils.exec_for_each load_slides_of, presentation.chapters, (err) ->
          return callback(err) if err?
          return callback(undefined, presentation)


load_entire_presentation_from_id = (id, callback) ->
  load_entire_presentation_with_query "select from V where _type = 'presentation' and id = '#{id}'", callback

load_entire_presentation_from_path = (path, callback) ->
  path_parts = path.split("/")
  catalog_name = path_parts[0]
  presentation_name = path_parts[1]

  load_entire_presentation_with_query "select from V where _type = 'presentation' and id = '#{presentation_name}' and out.label CONTAINSALL 'part_of' and out.in.id CONTAINSALL '#{catalog_name}'", callback

load_user_of = (comment, callback) ->
  db.fromVertex(comment).inVertexes "authored_comment", (err, users) ->
    return callback(err) if err?
    return callback("Too many users") if users.length > 1
    comment.user = users[0]
    callback()

load_comments_of = (node, callback) ->
  db.fromVertex(node).inVertexes "comment_of", (err, comments) ->
    return callback(err) if err?
    node.comments = _.sortBy comments, (comment) -> -1 * comment.time
    utils.exec_for_each load_user_of, node.comments, (err) ->
      return callback(err) if err?
      callback(undefined, node)

load_chapters_of = (presentation, callback) ->
  db.fromVertex(presentation).inVertexes "chapter_of", (err, chapters) ->
    return callback(err) if err?
    presentation.chapters = _.sortBy chapters, (chapter) -> chapter._index
    return callback(undefined, presentation)

load_slides_of = (chapter, callback) ->
  db.fromVertex(chapter).inVertexes "slide_of", (err, slides) ->
    return callback(err) if err?
    chapter.slides = _.sortBy slides, (slide) -> slide.time
    utils.exec_for_each load_comments_of, slides, (err) ->
      return callback(err) if err?
      return callback(undefined, chapter)

remove_storage_fields_from_presentation = (presentation) ->
  clean_comments_in = (element) ->
    if element.comments?
      for comment in element.comments
        clean comment
        delete comment.user

  clean = (element) ->
    delete element.in
    delete element.out
    delete element._type
    delete element._index
    delete element["@class"]
    delete element["@type"]
    delete element["@version"]
    delete element["@rid"]

  clean presentation
  clean_comments_in presentation
  if presentation.chapters?
    for chapter in presentation.chapters
      clean chapter
      if chapter.slides?
        for slide in chapter.slides
          clean slide
          clean_comments_in slide

exports.load_chapters_of = load_chapters_of
exports.load_entire_presentation_from_path = load_entire_presentation_from_path
exports.load_entire_presentation_from_id = load_entire_presentation_from_id
exports.load_presentation_from_id = load_presentation_from_id
exports.init = init
exports.list_catalogs_with_presentation_count = list_catalogs_with_presentation_count
exports.catalog_name_to_node = catalog_name_to_node
exports.from_user_to_presentations = from_user_to_presentations
exports.from_catalog_to_presentations = from_catalog_to_presentations
exports.create_comment = create_comment
exports.remove_storage_fields_from_presentation = remove_storage_fields_from_presentation
exports.save = save