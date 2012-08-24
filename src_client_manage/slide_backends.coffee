class SlideShare

  constructor: () ->
    @slideshare_infos = {}
    
  handle: (url) ->
    url.toLowerCase().indexOf("slideshare.net") isnt -1
    
  thumb_type_of: (url) ->
    "swf"

  to_doc_id = (url) ->
    url.substring url.lastIndexOf("/") + 1, url.indexOf("#")
    
  to_slide_number = (url) ->
    parseInt url.substr url.indexOf("#") + 1
      
  preload: (slide, callback) ->
    doc_id = to_doc_id(slide.url)
    return callback(undefined, slide) if @slideshare_infos[doc_id]?
    $.get "/m/api/slideshare/#{doc_id}", (ss) =>
      @slideshare_infos[doc_id] = ss
      callback(undefined, slide)

  slide_info: (slide, callback) ->
    doc_id = to_doc_id slide.url
    number = to_slide_number slide.url
    thumb = @slideshare_infos[doc_id].Show.Slide[number - 1].Src
    callback undefined, slide,
      public_url: slide.public_url
      number: number
      thumb: thumb
      
  change_slide_number: (model, model_selector, slide_number) ->
    slide = model.get model_selector
    url = slide.url.substring(0, slide.url.lastIndexOf("#") + 1).concat(slide_number)
    model.set "#{model_selector}.url", url
      
class DummySlideBackend

  handle: (url) -> true

  thumb_type_of: (url) ->
    return "swf" if url.indexOf(".swf") isnt -1
    "img"

  preload: (slide, callback) ->
    callback undefined, slide
    
  slide_info: (slide, callback) ->
    callback undefined, slide, 
      public_url: slide.url
      thumb: slide.url

@presentzorg.slide_backends = {}
@presentzorg.slide_backends.SlideShare = SlideShare
@presentzorg.slide_backends.DummySlideBackend = DummySlideBackend