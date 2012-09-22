class Dummy

  constructor: () ->
    @import_file_value_column = "Slide URL"

  handle: (url) -> true

  thumb_type_of: (url) ->
    return "swf" if url.indexOf(".swf") isnt -1
    "img"

  slide_info: (slide, callback) ->
    if utils.is_url_valid(slide.url)
      callback undefined, slide,
        public_url: slide.url
        slide_thumb: slide.url
    else
      callback("Invalid URL: '#{slide.url}'")

  first_slide: (slideshow) ->
    slide_backends.make_new_slide(slideshow.url, 0, slideshow.public_url)

  slideshow_info: (url, callback) ->
    @slide_info url: url, callback

  url_from_public_url: (slide, callback) ->
    if utils.is_url_valid slide.public_url
      callback undefined, slide.public_url
    else
      callback("Invalid URL: #{slide.public_url}")

  set_slide_value_from_import: (slide, slide_url) ->
    slide.url = slide_url
    slide.public_url = slide_url

  check_slide_value_from_import: (slide, slide_number, callback) ->
    callback()

  make_new_from: (slide) ->
    new_slide = @slide_backends.make_new_slide(slide.url.substr(0, slide.url.lastIndexOf("/") + 1), slide.time)
    new_slide._thumb_type = "img"
    new_slide.slide_thumb = slide.url
    new_slide

@slide_backends.Dummy = Dummy