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
  
if exports?
  root = exports
else
  root = (@utils = {})

root.exec_for_each = exec_for_each
root.cut_string_at = cut_string_at