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

  clean_url = (url) ->
    url = Uri(url)
    "#{url.protocol()}://#{url.host()}#{url.path()}"

  all_slides_of: (url, public_url, duration) ->
    doc_id = @to_doc_id(url)
    ss_slides = @slideshare_infos[doc_id].Show.Slide
    mean_slide_duration = Math.floor(duration / ss_slides.length)
    slides = []
    time = 0
    for ss_slide, idx in ss_slides
      slide = slide_backends.make_new_slide(make_url(doc_id, idx + 1), time, public_url)
      slides.push slide
      time += mean_slide_duration
    slides

  slideshow_info: (public_url, callback) ->
    public_url = "http://#{public_url}" unless _.str.startsWith(public_url, "http://")
    public_url = clean_url(public_url)
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
      return callback("Invalid slide number #{number} (last slide is number is #{slides.length})") if number > slides.length

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

    return callback("Invalid URL") if !utils.is_url_valid(slide.public_url)

    public_url = slide.public_url = clean_url(slide.public_url)

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

  set_slide_value_from_import: (slide, slide_number) ->
    slide.url = @change_slide_number(slide.url, slide_number)

  check_slide_value_from_import: (slide, slide_number, callback) ->
    new_slide = _.clone slide
    new_slide.url = @change_slide_number(new_slide.url, slide_number)
    @slide_info new_slide, callback

  make_new_from: (slide) ->
    new_slide = @slide_backends.make_new_slide(slide.url, slide.time, slide.public_url)
    new_slide._thumb_type = "swf"
    new_slide.number = @to_slide_number(slide.url)
    new_slide.slide_thumb = @slideshare_infos[@to_doc_id(slide.url)].Show.Slide[new_slide.number - 1].Src
    new_slide

@slide_backends.SlideShare = SlideShare
