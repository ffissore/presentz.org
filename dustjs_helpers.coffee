draw_boxes = (number_of_boxes) ->
  return (chunk, context, bodies) ->
    boxes = context.current()
    index = 0
    for box in boxes
      index++
      chunk = chunk.render bodies.block, context.push(box)
      if index is number_of_boxes
        chunk = chunk.write "<div class=\"clear\"></div>"
        index = 0
    chunk

onebased = (chunk, context, bodies) ->
  chunk.write context.stack.index + 1
  chunk

if exports?
  root = exports
else
  root = (@dustjs_helpers = {})

root.draw_boxes = draw_boxes
root.onebased = onebased