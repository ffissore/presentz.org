exec_for_each = (callable, elements, callback) ->
  return callback(undefined, elements) if elements.length is 0
  exec_times = 0
  for element in elements
    callable element, (err) ->
      return callback(err) if err?
      exec_times++
      return callback(undefined, elements) if exec_times is elements.length

cut_string_at = (str, size) ->
  if str.length > size + 3
    return "#{str.substring(0, size)}..."
  str
  
remove_unwanted_fields_from = (obj, fields_to_remove) ->
  for key, value of obj
    delete obj[key] if key in fields_to_remove
  
ensure_only_wanted_fields_in = (obj, allowed_fields) ->
  for key, value of obj
    delete obj[key] unless key in allowed_fields
    
visit_presentation = (presentation, func) ->
  func_args = [null]
  for arg, idx in arguments when idx > 1
    func_args.push arg
    
  apply_on = (first_arg) ->
    func_args[0] = first_arg
    func.apply null, func_args

  apply_on presentation
  if presentation.comments?
    for comment in presentation.comments
      apply_on comment
      apply_on comment.user if comment.user?

  return unless presentation.chapters?

  for chapter in presentation.chapters
    apply_on chapter
    apply_on chapter.video if chapter.video?
    if chapter.slides?
      for slide in chapter.slides
        apply_on slide
        if slide.comments?
          for comment in slide.comments
            apply_on comment
            apply_on comment.user if comment.user?
  return
  
if exports?
  root = exports
else
  root = (@utils = {})

root.exec_for_each = exec_for_each
root.cut_string_at = cut_string_at
root.remove_unwanted_fields_from = remove_unwanted_fields_from
root.ensure_only_wanted_fields_in = ensure_only_wanted_fields_in
root.visit_presentation = visit_presentation