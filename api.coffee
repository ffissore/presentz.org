storage = null

init = (s) ->
  storage = s

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

exports.init = init
exports.presentations = presentations
exports.presentation_update = presentation_update

###
exports.mines_authored= (req, res) ->
  api.db.fromVertex(req.user).outVertexes "authored", (err, presentations) ->
    for p in presentations
      delete p.chapters

    res.send presentations

exports.mines_held= ->
  throw new Error
###