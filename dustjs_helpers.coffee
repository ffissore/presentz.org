draw_boxes = (number_of_boxes) ->
  return (chunk, context, bodies) ->
    boxes = context.current()
    for box, index in boxes
      chunk = chunk.render bodies.block, context.push(box)
      if (index + 1) % number_of_boxes is 0
        chunk = chunk.write "<div class=\"clear\"></div>"
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