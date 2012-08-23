class SlideShare

  constructor: () ->
    @slideshare_infos = {}

  handle: (url) ->
    url.toLowerCase().indexOf("slideshare.net") != -1

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
      
class DummySlideBackend
  
  handle: (url) -> true
  
  preload: (slide, callback) ->
    callback undefined, slide
    
  slide_info: (slide, callback) ->
    callback undefined, slide, 
      public_url: slide.url
      thumb: slide.url

@presentzorg.slide_backends = {}
@presentzorg.slide_backends.SlideShare = SlideShare
@presentzorg.slide_backends.DummySlideBackend = DummySlideBackend