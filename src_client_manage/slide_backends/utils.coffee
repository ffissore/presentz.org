make_new_slide = (url, time, public_url) ->
  new_slide =
    url: url
    time: time
  if public_url?
    new_slide.public_url = public_url
  new_slide

@slide_backends.make_new_slide = make_new_slide