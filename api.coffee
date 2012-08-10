storage = null

exports.init = (s) ->
  storage = s

exports.my_presentations = (req, res, next) ->
  storage.from_user_to_presentations req.user, (err, presentations) ->
    return next(err) if err?

    for presentation in presentations
      storage.remove_storage_fields_from_presentation presentation
      
    res.send presentations

###
exports.mines_authored= (req, res) ->
  api.db.fromVertex(req.user).outVertexes "authored", (err, presentations) ->
    for p in presentations
      delete p.chapters

    res.send presentations

exports.mines_held= ->
  throw new Error
###