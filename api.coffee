api = {}

exports.init = (db) ->
  api.db = db
  @

exports.mines_authored = (req, res) ->
  api.db.fromVertex(req.user).outVertexes "authored", (err, presentations) ->
    for p in presentations
      delete p.chapters

    res.send presentations

exports.mines_held = ->
  throw new Error