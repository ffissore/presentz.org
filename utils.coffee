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
  
if exports?
  root = exports
else
  root = (@utils = {})

root.exec_for_each = exec_for_each
root.cut_string_at = cut_string_at
root.remove_unwanted_fields_from = remove_unwanted_fields_from
root.ensure_only_wanted_fields_in = ensure_only_wanted_fields_in