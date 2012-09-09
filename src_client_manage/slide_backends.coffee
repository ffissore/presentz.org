class SlideShare

  constructor: (@presentzSlideShare) ->
    @slideshare_infos = {}
    @slideshare_url_to_slideshows = {}
    @import_file_value_column = "Slide Index"

  handle: (url) ->
    @presentzSlideShare.handle url: url

  thumb_type_of: (url) -> "swf"

  to_doc_id: (url) ->
    @presentzSlideShare.slideId url: url

  to_slide_number: (url) ->
    parseInt(@presentzSlideShare.slideNumber(url: url))
    
  make_url = (doc_id, slide_number) ->
    "http://www.slideshare.net/#{doc_id}##{slide_number}"

  all_slides_of: (url, public_url, duration) ->
    doc_id = @to_doc_id(url)
    ss_slides = @slideshare_infos[doc_id].Show.Slide
    mean_slide_duration = Math.floor(duration / ss_slides.length)
    slides = []
    time = 0
    for ss_slide, idx in ss_slides
      slide = 
        time: time
        url: make_url(doc_id, idx + 1)
        public_url: public_url
      time += mean_slide_duration
      slides.push slide
    slides    
    
  slideshow_info: (public_url, callback) ->
    public_url = "http://#{public_url}" unless _.str.startsWith(public_url, "http://")
    @url_from_public_url url: "#{public_url}#1", public_url: public_url, (err, url, slideshow) =>
      return callback(err) if err?
      
      slide =
        url: url
        public_url: public_url
      @slide_info slide, (err, slide, slide_info) ->
        return callback(err) if err?
        slide_info.url = slide.url
        slide_info.title = slideshow.Title
        callback undefined, slide, slide_info

  slide_info: (slide, callback) ->
    doc_id = @to_doc_id slide.url

    pack_response = (doc_id, slide, callback) =>
      number = @to_slide_number slide.url
      slides = @slideshare_infos[doc_id].Show.Slide
      return callback("Invalid slide number #{number}") if number > slides.length

      slide_thumb = slides[number - 1].Src
      callback undefined, slide,
        public_url: slide.public_url
        number: number
        slide_thumb: slide_thumb

    if @slideshare_infos[doc_id]?
      pack_response doc_id, slide, callback
    else
      $.get "/m/api/slideshare/#{doc_id}", (ss) =>
        @slideshare_infos[doc_id] = ss
        pack_response doc_id, slide, callback

  url_from_public_url: (slide, callback) ->
    slide_number = @to_slide_number slide.url
    public_url = slide.public_url

    if @slideshare_url_to_slideshows[public_url]?
      slideshow = @slideshare_url_to_slideshows[public_url]
      callback undefined, make_url(slideshow.PPTLocation, slide_number), slideshow
      return

    $.get "/m/api/slideshare/url_to_doc_id", { url: public_url }, (ss) =>
      return callback(ss.SlideShareServiceError.Message["$t"]) if ss.SlideShareServiceError? 
      
      slideshow = ss.Slideshow
      @slideshare_url_to_slideshows[slide.public_url] = slideshow
      callback undefined, make_url(slideshow.PPTLocation, slide_number), slideshow

  change_slide_number: (old_url, slide_number) ->
    old_url.substring(0, old_url.lastIndexOf("#") + 1).concat(slide_number)

  set_slide_value_from_import: (slide, slide_index) ->
    slide.url = @change_slide_number(slide.url, slide_index)

class DummySlideBackend

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

@presentzorg.slide_backends = {}
@presentzorg.slide_backends.SlideShare = SlideShare
@presentzorg.slide_backends.DummySlideBackend = DummySlideBackend