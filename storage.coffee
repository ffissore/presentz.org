utils = require "./utils"
_ = require "underscore"

db = null

init = (database) ->
  db = database
  @

save = (vertex, callback) ->
  db.save vertex, callback

create = (vertex, callback) ->
  db.createVertex vertex, callback

link_slide_to_chapter = (slide, chapter, callback) ->
  db.createEdge slide, chapter, { label: "slide_of" }, callback

link_chapter_to_presentation = (chapter, presentation, callback) ->
  db.createEdge chapter, presentation, { label: "chapter_of" }, callback

link_user_to_presentation = (user, presentation, callback) ->
  db.createEdge user, presentation, { label: "authored" }, callback

cascading_save = (vertex, callback) ->
  db.cascadingSave vertex, callback

count_presentations_in_catalog = (catalog, callback) ->
  db.getInEdges catalog, "part_of", (err, edges) ->
    return callback(err) if err?
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

find_user_by_username_by_social = (social_column, user_name, callback) ->
  db.command "select from V where _type = 'user' and #{social_column} is not null and user_name = '#{user_name}'", (err, users) ->
    return callback(err) if err?
    return callback("no record found") if users.length is 0
    return callback("too many records found") if users.length > 1
    callback(undefined, users[0])

load_presentation_from_id = (presentation_id, callback) ->
  db.command "select from V where _type = 'presentation' and presentation_id = '#{presentation_id}'", (err, presentations) ->
    return callback(err) if err?
    return callback("no record found") if presentations.length is 0
    return callback("too many records found") if presentations.length > 1
    callback(undefined, presentations[0])

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


load_entire_presentation_from_id = (presentation_id, callback) ->
  load_entire_presentation_with_query "select from V where _type = 'presentation' and id = '#{presentation_id}'", callback

load_entire_presentation_from_catalog = (catalog_name, presentation_id, callback) ->
  load_entire_presentation_with_query "select from V where _type = 'presentation' and id = '#{presentation_id}' and out.label CONTAINSALL 'part_of' and out.in.id CONTAINSALL '#{catalog_name}'", callback

load_entire_presentation_from_users_catalog = (social_prefix, user_name, presentation_id, callback) ->
  load_entire_presentation_with_query "select from V where _type = 'presentation' and id = '#{presentation_id}' and in.label CONTAINS 'authored' and in.out.#{social_prefix}.size() = 1 and in.out.user_name CONTAINSALL '#{user_name}'", callback

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

delete_slide = (rid, callback) ->
  delete_nodes = (nodes, callback) ->
    return callback() if nodes.length is 0

    deleted = 0
    for node in nodes
      db.delete node, (err) ->
        return callback(err) if err?
        deleted++
        callback() if nodes.length is deleted

  db.loadRecord "##{rid}", (err, node) ->
    return callback(err) if err?

    db.command "select from (traverse V.in, E.out from ##{rid}) where label = 'authored_comment'", (err, authored_edges) ->
      return callback(err) if err?
      delete_nodes authored_edges, (err) ->
        return callback(err) if err?

        db.command "select from (traverse V.in, E.out from ##{rid}) where label = 'comment_of'", (err, comment_edges) ->
          return callback(err) if err?
          delete_nodes comment_edges, (err) ->
            return callback(err) if err?

            db.command "select from (traverse V.in, E.out from ##{rid}) where _type = 'comment'", (err, comments) ->
              return callback(err) if err?
              delete_nodes comments, (err) ->
                return callback(err) if err?

                db.getOutEdges node, "slide_of", (err, edges) ->
                  return callback(err) if edges.length isnt 1

                  edge_rid = edges[0]["@rid"]

                  db.fromVertex(node).outVertexes "slide_of", (err, chapters) ->
                    return callback(err) if chapters.length isnt 1

                    chapter = chapters[0]
                    chapter.in = _.without(chapter.in, edge_rid)

                    db.save chapter, (err, chapter) ->
                      return callback(err) if err?

                      delete_nodes edges, (err) ->
                        return callback(err) if err?

                        db.delete node, callback

exports.load_chapters_of = load_chapters_of
exports.load_entire_presentation_from_catalog = load_entire_presentation_from_catalog
exports.load_entire_presentation_from_id = load_entire_presentation_from_id
exports.load_entire_presentation_from_users_catalog = load_entire_presentation_from_users_catalog
exports.load_presentation_from_id = load_presentation_from_id
exports.init = init
exports.list_catalogs_with_presentation_count = list_catalogs_with_presentation_count
exports.catalog_name_to_node = catalog_name_to_node
exports.from_user_to_presentations = from_user_to_presentations
exports.from_catalog_to_presentations = from_catalog_to_presentations
exports.create_comment = create_comment
exports.save = save
exports.cascading_save = cascading_save
exports.create = create
exports.link_slide_to_chapter = link_slide_to_chapter
exports.link_chapter_to_presentation = link_chapter_to_presentation
exports.link_user_to_presentation = link_user_to_presentation
exports.find_user_by_username_by_social = find_user_by_username_by_social
exports.delete_slide = delete_slide
